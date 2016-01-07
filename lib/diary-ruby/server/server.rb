require 'sinatra'
require 'json'
require 'rdiscount'
require 'tilt/erb'

module Diary
  class Server < Sinatra::Base
    configure :production, :development do
      enable :logging
    end

    def self.passphrase=(val)
      @db_passphrase = val
    end

    def self.database=(val)
      @db_path = val
    end

    def self.store=(val)
      @store = val
    end

    def self.db_path
      @db_path
    end

    def self.db_passphrase
      @db_passphrase
    end

    def store
      if @store.nil?
        if settings.db_passphrase.nil?
          @store = Diary::Store.new(settings.db_path)
        else
          @store = Diary::SecureStore.new(settings.db_path, settings.db_passphrase)
        end
      end

      @store
    end

    get '/' do
      keys = store.read(:entries)

      if keys.nil?
        store.write do |db|
          db[:entries] = []
        end

        keys = []
      end

      @entries = keys.uniq.map {|entry_key|
        entry = store.read(entry_key)

        if entry
          logger.debug "LOAD #{ entry }"
          Entry.from_store(entry)
        else
          nil
        end
      }.compact

      logger.info "returning keys: #{ keys }"
      logger.info "returning entries: #{ @entries }"

      erb :index
    end

    get '/entry/:key' do
      content_type :json

      key = params[:key]
      entry_hash = store.read(key)
      entry = Entry.from_store(entry_hash)

      content = RDiscount.new entry.text
      entry_hash[:formatted] = content.to_html

      if entry
        entry_hash.to_json
      else
        {}
      end
    end

    # create
    post '/entries' do
      logger.info "ENTRY"

      begin
        tags = params[:tags].split(',').map(&:strip)
      rescue
        tags = []
      end

      entry = Entry.new(nil,
                params[:day],
                params[:time],
                tags,
                params[:text],
                nil)

      store.write_entry(entry)

      redirect to('/')
    end
  end
end

