require 'test_helper'
require 'sqlite3'

class EntryTest < Minitest::Test
  def setup
    database = Diary::Database.new(':memory:')

    # make sure we're always up to date
    migrator = Diary::Migrator.new(database)
    migrator.migrate!

    Diary::Model.connection = database.database
  end

  def test_create_minimal_entry
    entry = Diary::Entry.new(day: '1', time: '2')
    entry.save!
    assert_equal 1, Diary::Entry.count
  end

  def test_update_entry
    # create it
    entry = Diary::Entry.new(day: '1', time: '2', body: 'a')
    entry.save!
    assert_equal 1, Diary::Entry.count
    assert_equal 'a', entry.body

    # check it
    fentry = Diary::Entry.find(date_key: '1-2')
    assert_equal 'a', fentry.body


    # reopen an entry with the same values
    entry = Diary::Entry.new(day:'1', time:'2', body: 'b')
    entry.save!
    assert_equal 1, Diary::Entry.count
    assert_equal 'b', entry.body

    fentry = Diary::Entry.find(date_key: '1-2')
    assert_equal 'b', fentry.body
  end
end
