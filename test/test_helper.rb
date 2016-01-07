$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'diary-ruby'

require 'minitest/autorun'
require 'minitest/display'

MiniTest::Display.options = {
  suite_names: true,
  output_slow: false,
  output_slow_suites: false,
}

def fixture_path(filename)
  File.join(File.dirname(__FILE__), 'fixtures', filename)
end
