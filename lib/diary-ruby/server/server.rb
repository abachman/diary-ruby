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
      @entries = Entry.order('created_at DESC').map do |entry_hash|
        Entry.from_hash(entry_hash)
      end

      logger.info "returning keys: #{ keys }"
      logger.info "returning entries: #{ @entries }"

      erb :index
    end

    get '/entry/:key' do
      content_type :json

      key = params[:key]
      entry_hash = Entry.find(date_key: key)

      if entry_hash
        entry = Entry.from_store(entry_hash)
        content = RDiscount.new entry['body']
        entry_hash[:formatted] = content.to_html
        entry_hash.to_json
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
        body: params[:body],
      )

      store.write_entry(entry)

      redirect to('/')
    end
  end
end

