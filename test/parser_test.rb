require 'test_helper'

class FakeStore
  def read(key)
    return 'FAKE'
  end
end

class ParserTest < Minitest::Test
  def setup
    @file_path = fixture_path('test.md')
  end

  def teardown
    File.unlink(@file_path)
  end

  def test_parse_file
    entry = Diary::Entry.new(nil, text: 'asdf', day: '0000-00-00', time:'00:00:00')
    File.open(@file_path, 'w') do |f|
      f.print Diary::Entry.generate(entry.to_hash, FakeStore.new)
    end

    parsed_entry = Diary::Parser.parse_file(open(@file_path))

    assert parsed_entry
    %w(version text day time tags title key).each do |field|
      method = field.to_sym
      assert_equal entry.send(method), parsed_entry.send(method)
    end
  end
end
