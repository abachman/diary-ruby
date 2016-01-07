require 'test_helper'

class SecureStoreTest < Minitest::Test

  def open_new_store
    Diary::SecureStore.new(@fixture_file, @passphrase)
  end

  def setup
    @passphrase = "**GOOD GRIEF** that's not a lot of tests"
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

  def test_opening_store_with_bad_passphrase_raises_error
    # write to good store
    @store.write do |db|
      db[:entries] = [1, 2, 3]
    end

    # reopen with known bad passphrase
    bad_passphrase = "now they're just making things up"
    bad_store = Diary::SecureStore.new(@fixture_file, bad_passphrase)

    retval = nil

    assert_raises(PStore::Error) do
      retval = bad_store.read(:entries)
    end

    assert_nil retval
  end

end
