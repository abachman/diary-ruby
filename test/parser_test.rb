require 'test_helper'

class FakeStore
  def read(key)
    return 'FAKE'
  end
end

class ParserTest < Minitest::Test
  def setup
    @file_path = fixture_path('test.md')
    setup_fixture_db
  end

  def teardown
    File.unlink(@file_path) if File.exists?(@file_path)
  end

  def test_parse_file
    entry = Diary::Entry.new(body: 'asdf', day: '0000-00-00', time:'00:00:00')
    File.open(@file_path, 'w') do |f|
      f.print Diary::Entry.generate(entry.to_hash)
    end

    parsed_entry = Diary::Parser.parse_file(open(@file_path))

    assert parsed_entry
    %w(body day time tags title date_key).each do |field|
      method = field.to_sym
      assert_equal entry.send(method), parsed_entry.send(method)
    end
  end
end
