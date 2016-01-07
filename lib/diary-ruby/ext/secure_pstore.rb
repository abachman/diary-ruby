
require 'pstore'
require 'diary-ruby/ext/encryptor'

#
# Wrap PStore, combine with OpenSSL::Cipher to secure store on disk with a
# given passphrase
#
# SecurePStore
#
# Useable exactly like PStore except for initialization.
#
# With PStore:
#
#     wiki = PStore.new("wiki_pages.pstore")
#     wiki.transaction do  # begin transaction; do all of this or none of it
#       # store page...
#       wiki[home_page.page_name] = home_page
#       # ensure that an index has been created...
#       wiki[:wiki_index] ||= Array.new
#       # update wiki index...
#       wiki[:wiki_index].push(*home_page.wiki_page_references)
#     end                  # commit changes to wiki data store file
#
# With SecurePStore:
#
#     wiki = SecurePStore.new("wiki_pages.pstore", passphrase: 'do it this way instead')
#     wiki.transaction do  # begin transaction; do all of this or none of it
#       # store page...
#       wiki[home_page.page_name] = home_page
#       # ensure that an index has been created...
#       wiki[:wiki_index] ||= Array.new
#       # update wiki index...
#       wiki[:wiki_index].push(*home_page.wiki_page_references)
#     end                  # commit changes to wiki data store file
#
# Simple!
#
class SecurePStore < PStore
  # :call-seq:
  #   initialize( file_name, secure_opts = {} )
  #
  # Creates a new SecureStore object, which will store data in +file_name+.
  # If the file does not already exist, it will be created.
  #
  # Options passed in through +secure_opts+ will be used behind the scenes
  # when writing the encrypted file to disk.
  def initialize file_name, secure_opts = {}
    @opt = secure_opts
    super
  end

  # Override PStore's private low-level storage methods, similar to YAML::Store
  #
  def dump(table)  # :nodoc:
    marshalled = Marshal::dump(table)
    # return encrypted
    Encryptor.encrypt(marshalled, @opt[:passphrase])
  end

  def load(content)  # :nodoc:
    begin
      dcontent = Encryptor.decrypt(content, @opt[:passphrase])
      Marshal::load(dcontent)
    rescue OpenSSL::Cipher::CipherError => ex
      raise PStore::Error.new("Failed to decrypt stored data: #{ ex.message }")
    end
  end

  def marshal_dump_supports_canonical_option?
    false
  end

  def empty_marshal_data
    @empty_marshal_data ||= begin
                              m = Marshal.dump({})
                              Encryptor.encrypt(m, @opt[:passphrase])
                            end
  end

  def empty_marshal_checksum
    @empty_marshal_checksum ||= begin
                                  Digest::MD5.digest(empty_marshal_data)
                                end
  end
end
