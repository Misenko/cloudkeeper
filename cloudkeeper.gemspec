# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloudkeeper/version'

Gem::Specification.new do |spec|
  spec.name          = 'cloudkeeper'
  spec.version       = Cloudkeeper::VERSION
  spec.authors       = ['Michal Kimle']
  spec.email         = ['kimle.michal@gmail.com']

  spec.summary       = 'Synchronize cloud appliances between AppDB and cloud platforms'
  spec.description   = 'Synchronize cloud appliances between AppDB and cloud platforms'
  spec.homepage      = 'https://github.com/Misenko/cloudkeeper'
  spec.license       = 'Apache License, Version 2.0'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 11.2'
  spec.add_development_dependency 'rspec', '~> 3.5'
  spec.add_development_dependency 'rubocop', '~> 0.42'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.7'
  spec.add_development_dependency 'rspec-collection_matchers', '~> 1.1'
  spec.add_development_dependency 'simplecov', '~> 0.12'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'vcr', '~> 3.0'
  spec.add_development_dependency 'webmock', '~> 2.1'

  spec.add_runtime_dependency 'thor', '~> 0.19'
  spec.add_runtime_dependency 'yell', '~> 2.0'
  spec.add_runtime_dependency 'mixlib-shellout', '~> 2.2'
  spec.add_runtime_dependency 'grpc', '~> 1.0'
  spec.add_runtime_dependency 'settingslogic', '~> 2.0'
  spec.add_runtime_dependency 'zaru', '~> 0.1'
  spec.add_runtime_dependency 'activesupport', '~> 4.0'

  spec.required_ruby_version = '>= 2.2.0'
end