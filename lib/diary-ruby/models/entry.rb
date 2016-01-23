TEMPLATE = "# last entry posted at %{last_update_at}

DAY   %{day}
TIME  %{time}
TAGS  %{tags}
TITLE %{title}

---

%{body}
"

require 'rdiscount'
require 'diary-ruby/model'

module Diary
  class Entry < Model
    attr_accessor :day, :time, :tags, :body, :link, :title, :date_key

    def self.table_name
      'entries'
    end

    def self.from_hash(record)
      entry = self.new(
        day: record['day'],
        time: record['time'],
        body: record['body'],
        title: record['title'],
        date_key: record['date_key'],
      )

      # taggings!
      begin
        tag_ids = select_values('select tag_id from taggings where entry_id = ?', [entry.identifier])
        bind_hold = tag_ids.map {|_| '?'}.join(',')
        entry.tags = select_values("select name from tags where rowid in (#{ bind_hold })", *tag_ids)
      rescue => ex
        Diary.debug "FAILED TO LOAD TAGS. #{ ex.message }"
      end

      entry
    end

    def self.keygen(day, time)
      "%s-%s" % [day, time]
    end

    def self.generate(options={})
      options[:last_update_at] = connection.execute("select max(updated_at) from #{table_name}")[0] || ''

      # convert Arrays to dumb CSV
      options.each do |(k, v)|
        if v.is_a?(Array)
          options[k] = v.join(', ')
        end
      end

      TEMPLATE % options
    end

    def initialize(options={})
      @day = options[:day]
      @time = options[:time]
      @tags = options[:tags] || []
      @body = options[:body]
      @title = options[:title]

      if options[:date_key].nil?
        @date_key = identifier
      else
        @date_key = options[:date_key]
      end
    end

    def identifier
      self.class.keygen(day, time)
    end

    def formatted_body
      RDiscount.new(body).to_html
    end

    def truncated_body
      _truncated = body
      if _truncated.size > 40
        _truncated = "#{ _truncated[0..40] }..."
      end
      _truncated
    end

    def summary
      "#{ date_key }  #{ truncated_body }"
    end

    def to_hash
      {
        day: day,
        time: time,
        tags: tags,
        body: body,
        title: title,
        date_key: date_key,
      }
    end

    def save!
      if self.class.find(date_key: date_key)
        # update record
        sql = "UPDATE entries SET day=?, time=?, body=?, link=?, title=?, updated_at=#{timestamp_sql} WHERE date_key=?"
        self.class.execute(sql, day, time, body, link, title, date_key)
      else
        # insert
        sql = %[INSERT INTO entries (day, time, body, link, title, date_key, created_at, updated_at)
                VALUES              (?,   ?,    ?,    ?,    ?,     ?,        #{timestamp_sql}, #{timestamp_sql})]
        self.class.execute(sql, day, time, body, link, title, date_key)
      end

      begin
        update_tags!
      rescue => ex
        Diary.debug "FAILED TO UPDATE TAGS #{ tags.inspect }. #{ ex.message }"
      end
    end

    def update_tags!
      # clean out existing
      Diary.debug "CLEANING `taggings`"
      self.class.execute('delete from taggings where entry_id = ?', [identifier])

      # add back
      tags.each do |tag|
        # is tag in db?
        tag_id = self.class.select_value('select rowid from tags where name = ?', tag)

        if tag_id.nil?
          Diary.debug "CREATING TAG #{ tag.inspect }"

          # exists
          Diary.debug self.class.select_rows('PRAGMA table_info(tags)').inspect
          self.class.execute("insert into tags (name) values (?)", [tag])
          tag_id = self.class.select_value('select last_insert_rowid()')
        end

        Diary.debug "CREATING tagging"
        self.class.execute('insert into taggings (tag_id, entry_id) values (?, ?)', [tag_id, identifier])
      end
    end
  end
end

