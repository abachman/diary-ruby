TEMPLATE = "# last entry posted at %{last_update_at}

DAY   %{day}
TIME  %{time}
TAGS  %{tags}
TITLE %{title}

---

%{text}
"

require 'rdiscount'

module Diary
  class Entry
    attr_accessor :version, :day, :time, :tags, :text, :title, :key

    CURRENT_VERSION = 1

    def self.from_store(record)
      if record[:version] == 1
        self.new(
          record[:version],
          day: record[:day],
          time: record[:time],
          tags: record[:tags],
          text: record[:text],
          title: record[:title],
          key: record[:key],
        )
      end
    end

    def self.keygen(day, time)
      "%s-%s" % [day, time]
    end

    def self.generate(options={}, store)
      options[:last_update_at] = store.read(:last_update_at)

      # convert Arrays to dumb CSV
      options.each do |(k, v)|
        if v.is_a?(Array)
          options[k] = v.join(', ')
        end
      end

      TEMPLATE % options
    end

    def initialize(version, options={})
      @version = version || CURRENT_VERSION

      @day = options[:day]
      @time = options[:time]
      @tags = options[:tags] || []
      @text = options[:text]
      @title = options[:title]

      if options[:key].nil?
        @key = Entry.keygen(day, time)
      else
        @key = options[:key]
      end
    end

    def formatted_text
      RDiscount.new(text).to_html
    end

    def to_hash
      {
        version: version,
        day: day,
        time: time,
        tags: tags,
        text: text,
        title: '',
        key: key,
      }
    end
  end
end

