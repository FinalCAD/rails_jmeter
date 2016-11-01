# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rails_jmeter/version'

Gem::Specification.new do |spec|
  spec.name          = "rails_jmeter"
  spec.version       = RailsJmeter::VERSION
  spec.authors       = ["Steve Chung"]
  spec.email         = ["steve.chung7@gmail.com"]

  spec.summary       = %q{Structure your ruby-jmeter code in Rails testing style}
  spec.description   = %q{Structure your ruby-jmeter code in Rails testing style}
  spec.homepage      = "https://github.com/FinalCAD/rails_jmeter"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ruby-jmeter"
  spec.add_dependency "activesupport"
end
