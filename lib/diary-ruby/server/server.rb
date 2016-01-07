require 'sinatra'
require 'json'
require 'rdiscount'
require 'tilt/erb'

module Diary
  class Server < Sinatra::Base
    configure :production, :development do
      enable :logging
    end

    def self.store=(val)
      @store = val
    end

    def self.store
      @store
    end

    def store
      self.class.store
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

      entry = Entry.new(
        nil,
        day: params[:day],
        time: params[:time],
        tags: tags,
        text: params[:text],
      )

      store.write_entry(entry)

      redirect to('/')
    end
  end
end

