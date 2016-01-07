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

      def exists?
        !config_dir.nil?
      end

      def has_diary_config?(diary_identifier)
        load_global_settings
        global_settings.has_key?(diary_identifier)
      end

      def global_settings
        @global_settings || {}
      end

      # load a specific diary
      def load_config(diary_identifier)
        @config = load_config_for_diary(diary_identifier)
      end

      # default to current_diary
      def config
        @config ||= load_config_for_diary(current_diary)
      end

      private

      def load_config_for_diary(diary_identifier)
        if !exists?
          # no config file exists, build empty configuration options starting now
          {}
        else
          load_global_settings
          if global_settings.has_key?(diary_identifier)
            global_settings[diary_identifier]
          else
            # configuration for this diary doesn't exist, build empty
            # configuration options starting now
            {}
          end
        end
      end

      def load_global_settings
        @global_settings ||= begin
                               if exists?
                                 cf = File.join(config_dir, 'config.yaml')
                                 YAML.load(File.open(cf))
                               else
                                 {}
                               end
                             end
      end
    end
  end
end
