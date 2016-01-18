require 'test_helper'
require 'sqlite3'

module Diary
  class Boot < Model
    def self.table_name; 'boots'; end
  end
end

class ModelTest < Minitest::Test
  def setup
    @database = SQLite3::Database.new ':memory:'
    @database.execute %[
      CREATE TABLE IF NOT EXISTS `boots` (
        `a` TEXT,
        `b` TEXT,
        `c` INTEGER,
        `created_at` TEXT DEFAULT NULL,
        `updated_at` TEXT DEFAULT NULL
      );
    ]

    # add a couple records
    @database.execute "INSERT INTO `boots` VALUES ('a1', 'b1' , 'c1', strftime('%Y-%m-%dT%H:%M:%S+0000'), strftime('%Y-%m-%dT%H:%M:%S+0000'))"
    @database.execute "INSERT INTO `boots` VALUES ('a2', 'b2' , 'c2', strftime('%Y-%m-%dT%H:%M:%S+0000'), strftime('%Y-%m-%dT%H:%M:%S+0000'))"

    Diary::Model.connection = @database
  end

  def test_all_method
    records = Diary::Boot.all
    assert_equal 2, records.size
    first = records.first

    assert first.has_key?('a')
    assert first.has_key?('b')
    assert first.has_key?('c')
    assert first.has_key?('created_at')
    assert first.has_key?('updated_at')
  end

  def test_where_method
    records = Diary::Boot.where(a: 'a1')
    assert_equal 1, records.size
    first = records.first

    assert first.has_key?('a')
    assert first.has_key?('b')
    assert first.has_key?('c')
    assert first.has_key?('created_at')
    assert first.has_key?('updated_at')
  end

  def test_find_method
    record = Diary::Boot.find(a: 'a1')
    assert record.is_a?(Hash)

    assert_equal 'a1', record['a']
    assert_equal 'b1', record['b']
    assert_equal 'c1', record['c']
  end

  def test_each_method
    counter = 0
    Diary::Boot.each do |record|
      assert record.is_a?(Hash)
      assert record.has_key?('a')
      assert record.has_key?('b')
      assert record.has_key?('c')
      assert record.has_key?('created_at')
      assert record.has_key?('updated_at')
      counter += 1
    end
    assert_equal 2, counter

    counter = 0
    Diary::Boot.where(a: 'a1').each do |record|
      assert record.is_a?(Hash)
      assert record.has_key?('a')
      assert record.has_key?('b')
      assert record.has_key?('c')
      assert record.has_key?('created_at')
      assert record.has_key?('updated_at')
      counter += 1
    end
    assert_equal 1, counter
  end
end
