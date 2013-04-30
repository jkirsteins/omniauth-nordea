# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'omniauth/nordea/version'

Gem::Specification.new do |gem|
  gem.name          = "omniauth-nordea"
  gem.version       = Omniauth::Nordea::VERSION
  gem.authors       = ["Jānis Kiršteins"]
  gem.email         = ["janis@montadigital.com"]
  gem.description   = %q{OmniAuth strategy for Nordea bank}
  gem.summary       = %q{OmniAuth strategy for Nordea bank}
  gem.homepage      = ""
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'omniauth', '~> 1.0'
  gem.add_development_dependency 'rack-test'
  gem.add_development_dependency 'rspec', '~> 2.7'
  gem.add_development_dependency "bundler", "~> 1.3"
  gem.add_development_dependency "rake"
end
