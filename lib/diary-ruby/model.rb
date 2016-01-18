require 'diary-ruby/ext/concern'

module Diary
  module ModelQuery
    extend ActiveSupport::Concern

    module ClassMethods
      def columns
        @columns ||= connection.execute("PRAGMA table_info(#{table_name})")
      end

      def column_names
        @column_names ||= columns.map {|col_info| col_info[1]}
      end

      def results_to_hashes(array_of_rows)
        array_of_rows.map do |row|
          Hash[ column_names.zip(row) ]
        end
      end

      def materialize(array_of_rows)
        results_to_hashes(array_of_rows).map do |record_hash|
          if respond_to?(:from_hash)
            from_hash(record_hash)
          else
            record_hash
          end
        end
      end

      def find(attrs)
        where(attrs).first
      end

      def new_select_relation
        Diary::Query::Select.new(table_name, self)
      end

      %w(where order group_by limit exists?).each do |q_type|
        define_method(q_type.to_sym) do |*conditions|
          new_select_relation.send(q_type.to_sym, *conditions)
        end
      end

      %w(all first count).each do |q_type|
        define_method(q_type.to_sym) do
          new_select_relation.send(q_type.to_sym)
        end
      end

      %w(each map).each do |q_type|
        define_method(q_type.to_sym) do |&block|
          new_select_relation.send(q_type.to_sym, &block)
        end
      end

    end
  end

  class Model
    include ModelQuery

    class << self
      def connection=(db)
        @@connection = db
      end

      def connection
        @@connection
      end
    end
  end
end
