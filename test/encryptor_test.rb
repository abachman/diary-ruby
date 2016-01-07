require 'test_helper'
require 'diary-ruby/ext/encryptor'

class EncryptorTest < Minitest::Test
  def setup
    @passphrase = "all the time there are passphrase tricksters!"
    @message = "this is a secret message, keep it secret"
  end

  def test_encryption
    final = Encryptor.encrypt(@message, @passphrase)

    refute_nil final
    assert_equal 2, final.count('|')
  end

  def test_encryption_decryption
    final = Encryptor.encrypt(@message, @passphrase)

    refute_nil final
    assert_equal 2, final.count('|')

    original = Encryptor.decrypt(final, @passphrase)

    refute_nil original
    assert_equal @message, original
  end
end

