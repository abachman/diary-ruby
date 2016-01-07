require 'pathname'
require 'yaml'

DIARY_DIR = ".diaryrb"

module Diary
  # Read only app configuration
  #
  class Configuration
    class Error < StandardError
    end

    class << self
      attr_accessor :current_diary
      attr_accessor :verbose

      # Find config directory starting at current dir and then moving up the tree
      def config_dir(dir = Pathname.new("."))
        app_config_dir = dir + DIARY_DIR

        if dir.children.include?(app_config_dir)
          app_config_dir.expand_path
        else
          return nil if dir.expand_path.root?

          # go up the stack
          config_dir(dir.parent)
        end
      end

      def method_missing(method)
        config[method.to_s]
      end

      def config
        @config ||= begin
                      cd = config_dir
                      if cd.nil?
                        raise Diary::Configuration::Error.new("Failed to find configuration directory")
                      end

                      cf = File.join(cd, 'config.yaml')
                      config_settings = YAML.load(File.open(cf))
                      if config_settings.has_key?(current_diary)
                        config_settings[current_diary]
                      else
                        {}
                      end
                    end
      end
    end
  end
end
