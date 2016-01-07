require 'test_helper'
require 'diary-ruby/ext/secure_pstore'

class SecurePStoreTest < Minitest::Test
  def setup
    @passphrase = "all the time there are passphrase tricksters!"
    @fixture_file = fixture_path("test.#{Process.pid}.store")
    @secure_pstore = SecurePStore.new(@fixture_file, passphrase: @passphrase)
    # @secure_pstore = PStore.new(@fixture_file)
  end

  def teardown
    File.unlink(@fixture_file) rescue nil
  end

  def test_store_values_in_hash
    # open and write
    @secure_pstore.transaction do
      assert(@secure_pstore['key'] = 'value')
      assert_equal 'value', @secure_pstore['key']
    end

    # read
    @secure_pstore.transaction(true) do
      assert_equal 'value', @secure_pstore['key']
    end
  end

  def test_opening_new_file_in_readonly_mode_should_result_in_empty_values
    @secure_pstore.transaction(true) do
      assert_nil @secure_pstore[:foo]
      assert_nil @secure_pstore[:bar]
    end
  end

  def test_opening_new_file_in_readwrite_mode_should_result_in_empty_values
    @secure_pstore.transaction do
      assert_nil @secure_pstore[:foo]
      assert_nil @secure_pstore[:bar]
    end
  end

end
