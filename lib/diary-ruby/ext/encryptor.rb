# -*- encoding: utf-8 -*-
#
# Create an encrypted bundled string version of a message, given a particular
# passphrase.
#
# Decrypt a bundled document given a particular passphrase.
#
# NOTE: the encrypted bundle chooses a random initialization vector
# and salt and includes them in the bundle in plain text alongside the
# encrypted message.
#

require 'openssl'
require 'base64'

module Encryptor
  class Error < StandardError
  end

  def self.encrypt(msg, pwd)
    cipher = OpenSSL::Cipher.new 'AES-128-CBC'
    cipher.encrypt

    # random salt
    salt = OpenSSL::Random.random_bytes(16)

    # random initialization vector
    iv = cipher.random_iv

    iter = 20000
    key_len = cipher.key_len
    digest = OpenSSL::Digest::SHA256.new

    key = OpenSSL::PKCS5.pbkdf2_hmac(pwd, salt, iter, key_len, digest)
    cipher.key = key

    # Now encrypt the data:
    encrypted = cipher.update(msg)
    encrypted << cipher.final

    # And encode final format
    wrap(iv, salt, encrypted)
  end

  def self.decrypt(document, pwd)
    iv, salt, encrypted = unwrap(document)

    Diary.debug "DECRYPT WITH"
    Diary.debug "  iv    #{ Base64.encode64(iv) }"
    Diary.debug "  salt  #{ Base64.encode64(salt) }"
    Diary.debug "  msg   #{ Base64.encode64(encrypted) }"

    ## Decrypt
    cipher = OpenSSL::Cipher.new 'AES-128-CBC'
    cipher.decrypt
    cipher.iv = iv

    salt = salt
    iter = 20000
    key_len = cipher.key_len
    digest = OpenSSL::Digest::SHA256.new

    key = OpenSSL::PKCS5.pbkdf2_hmac(pwd, salt, iter, key_len, digest)
    cipher.key = key

    decrypted = cipher.update(encrypted)
    decrypted << cipher.final
  end

  def self.wrap(iv, salt, encrypted)
    [
      Base64.encode64(iv),
      Base64.encode64(salt),
      Base64.encode64(encrypted)
    ].join('|')
  end

  def self.unwrap(document)
    if document.is_a?(File)
      document = document.read
    end

    if document.count('|') != 2
      raise Encryptor::Error.new("Document is not a vaild encrypted store.")
    end

    iv64, salt64, encrypted64 = document.split('|')

    iv = Base64.decode64(iv64.to_s.strip)
    salt = Base64.decode64(salt64.to_s.strip)
    encrypted = Base64.decode64(encrypted64.to_s.strip)

    [iv, salt, encrypted]
  end
end
