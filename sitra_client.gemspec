# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sitra_client/version'

Gem::Specification.new do |spec|
  spec.name          = "sitra_client"
  spec.version       = SitraClient::VERSION
  spec.authors       = ["jeanbaptistevilain"]
  spec.email         = ["jbvilain@gmail.com"]
  spec.description   = %q{Sitra Client Gem}
  spec.summary       = %q{This gem wraps the SITRA JSON API}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_runtime_dependency "activemodel", "3.2.14"
end
