# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mandrake/version'

Gem::Specification.new do |spec|
  spec.name          = "mandrake"
  spec.version       = Mandrake::VERSION
  spec.authors       = ["namusyaka"]
  spec.email         = ["namusyaka@gmail.com"]
  spec.summary       = %q{Mandrake loads middlewares conditionally, and it provides two options and DSL for setting conditions}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/namusyaka/mandrake"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rack"
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
