require 'test_helper'

class StoreTest < Minitest::Test
  def open_new_store
    Diary::Store.new(@fixture_file)
  end

  def setup
    @fixture_file = fixture_path("test.#{Process.pid}.store")
    @store = open_new_store
  end

  def teardown
    File.unlink(@fixture_file) rescue nil
  end

  def test_read_from_new_store_file_returns_nil
    assert_nil @store.read(:entries)
  end

  def test_save_and_open_with_values
    @store.write do |db|
      db[:entries] = [1, 2, 3]
    end

    store_2 = open_new_store
    assert_equal [1, 2, 3], store_2.read(:entries)
  end

  def test_save_entry_in_store
    entry = Diary::Entry.new(nil, text: 'asdf', day: '0000-00-00', time:'00:00:00')
    @store.write_entry(entry)

    # reopen
    store_2 = open_new_store
    assert store_2[:entries]
    assert store_2[:entries].is_a?(Array)
    assert_equal 1, store_2[:entries].size
    assert store_2['0000-00-00-00:00:00']
    assert store_2['0000-00-00-00:00:00'].is_a?(Hash)

    entry_from_store = store_2['0000-00-00-00:00:00']
    assert_equal 'asdf', entry_from_store[:text]
    assert_equal '0000-00-00', entry_from_store[:day]
    assert_equal '00:00:00', entry_from_store[:time]

    entry_2 = Diary::Entry.from_store(entry_from_store)
    assert_equal 'asdf', entry_2.text
    assert_equal '0000-00-00', entry_2.day
    assert_equal '00:00:00', entry_2.time
  end

  def test_update_existing_entry
    entry = Diary::Entry.new(nil, text: 'asdf', day: '0000-00-00', time:'00:00:00')
    @store.write_entry(entry)

    # reopen
    store_2 = open_new_store
    assert store_2[:entries]
    assert store_2[:entries].is_a?(Array)
    assert_equal 1, store_2[:entries].size
    assert store_2['0000-00-00-00:00:00']
    assert store_2['0000-00-00-00:00:00'].is_a?(Hash)

    # update
    entry_2 = Diary::Entry.new(nil, text: 'test test', day: '0000-00-00', time:'00:00:00')
    store_2.write_entry(entry_2)

    assert store_2[:entries]
    assert store_2[:entries].is_a?(Array)
    assert_equal 1, store_2[:entries].size
    assert store_2['0000-00-00-00:00:00']
    assert store_2['0000-00-00-00:00:00'].is_a?(Hash)

    # check
    entry_from_store = @store['0000-00-00-00:00:00']
    assert_equal 'test test', entry_from_store[:text]
    assert_equal '0000-00-00', entry_from_store[:day]
    assert_equal '00:00:00', entry_from_store[:time]

    assert @store[:entries]
    assert @store[:entries].is_a?(Array)
    assert_equal 1, @store[:entries].size
    assert @store['0000-00-00-00:00:00']
    assert @store['0000-00-00-00:00:00'].is_a?(Hash)
  end
end
