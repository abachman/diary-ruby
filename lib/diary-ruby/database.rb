require 'sqlite3'
require 'diary-ruby/database/query'

module Diary
  class Database
    attr_reader :database

    def initialize(path)
      @database = SQLite3::Database.new(path)
    end

    def execute(*query)
      if block_given?
        @database.execute(*query) do |row|
          yield row
        end
      else
        @database.execute(*query)
      end
    end
  end
end
