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
      self.new(
        day: record['day'],
        time: record['time'],
        tags: record['tags'],
        body: record['body'],
        title: record['title'],
        date_key: record['date_key'],
      )
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
        @date_key = Entry.keygen(day, time)
      else
        @date_key = options[:date_key]
      end
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
        title: '',
        date_key: date_key,
      }
    end

    def timestamp
      "strftime('%Y-%m-%dT%H:%M:%S+0000')"
    end

    def save!
      if self.class.find(date_key: date_key)
        # update record
        sql = "UPDATE entries SET day=?, time=?, body=?, link=?, title=?, updated_at=#{timestamp} WHERE date_key=?"
        self.class.connection.execute(sql, [day, time, body, link, title, date_key])
      else
        # insert
        sql = %[INSERT INTO entries (day, time, body, link, title, date_key, created_at, updated_at)
                VALUES              (?,   ?,    ?,    ?,    ?,     ?,        #{timestamp}, #{timestamp})]
        self.class.connection.execute(sql, [day, time, body, link, title, date_key])
      end

      # TODO: update tags
    end
  end
end

