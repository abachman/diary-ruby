require 'pstore'
require 'diary-ruby/ext/secure_pstore'

DEFAULT_FILENAME = File.join(File.dirname(__FILE__), 'diary.pstore')
DEFAULT_PASSPHRASE = 'default'

module Diary
  class Store
    def initialize(fname=nil)
      fname ||= DEFAULT_FILENAME

      @path = fname
      @file = PStore.new(fname)
    end

    def path
      @path
    end

    def write_entry(entry)
      Diary.debug("WRITING ENTRY #{ entry.to_hash }")

      @file.transaction do |db|
        # entries index
        db[:entries] ||= []
        db[:entries] << entry.key unless db[:entries].include?(entry.key)

        # actual entry
        db[entry.key] = entry.to_hash.merge(
          updated_at: Time.now.utc.strftime('%c')
        )

        # reverse tags index (from tag to entries)
        db[:tags] ||= {}
        (entry.tags || []).each do |tag|
          db[:tags][tag] ||= []
          db[:tags][tag] = (db[:tags][tag] + [entry.key]).uniq
        end

        update_db_timestamp(db)
      end
    end

    def write
      @file.transaction do |db|
        yield db
        update_db_timestamp(db)
      end
    end

    def update_db_timestamp(db)
      db[:last_update_at] = Time.now.utc.strftime('%c')
    end

    def [](key)
      read(key)
    end

    def read(key)
      out = nil
      @file.transaction(true) do |db|
        out = db[key]
      end
      out
    end
  end

  class SecureStore < Store
    def initialize(fname=nil, passphrase=nil)
      fname ||= DEFAULT_FILENAME
      passphrase ||= DEFAULT_PASSPHRASE

      @path = fname
      @file = ::SecurePStore.new(fname, passphrase: passphrase)
    end
  end

end

