require "diary-ruby/version"
# require "diary-ruby/store"
require "diary-ruby/database"
require "diary-ruby/database/migrator"
require "diary-ruby/database/query"
require "diary-ruby/model"
require "diary-ruby/models/entry"
require "diary-ruby/parser"
require "diary-ruby/configuration"
require "diary-ruby/server/server"

module Diary
  def self.log(message)
    if Diary::Configuration.verbose
      puts message
    end
  end

  def self.debug(message)
    if Diary::Configuration.verbose
      puts message
    end
  end
end
