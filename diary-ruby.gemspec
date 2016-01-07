# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'diary-ruby/version'

Gem::Specification.new do |spec|
  spec.name          = "diary-ruby"
  spec.version       = Diary::VERSION
  spec.authors       = ["Adam Bachman"]
  spec.email         = ["adam.bachman@gmail.com"]
  spec.licenses      = ['GPL-3.0']

  spec.summary       = %q{A CLI diary: diaryrb}
  spec.description   = %q{A command line diary: diaryrb}
  spec.homepage      = "https://github.com/abachman/diary-ruby"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = ['diaryrb']
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", '~> 5.8'
  spec.add_development_dependency "minitest-display", '~> 0.3'

  spec.add_dependency 'sinatra', '~> 1.4'
  spec.add_dependency 'rdiscount', '~> 2.1'
  spec.add_dependency 'slop', '~> 4.2'
  spec.add_dependency 'launchy', '~> 2.4'
end
