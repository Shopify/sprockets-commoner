# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sprockets/commoner/version'

Gem::Specification.new do |spec|
  spec.name          = "sprockets-commoner"
  spec.version       = Sprockets::Commoner::VERSION
  spec.authors       = ["Bouke van der Bijl"]
  spec.homepage      = 'https://github.com/Shopify/sprockets-commoner'
  spec.email         = ["bouke@shopify.com"]
  spec.license       = 'MIT'

  spec.summary       = %q{Use Babel in Sprockets to compile modules for the browser}
  spec.description   = %q{Sprockets::Commoner uses Node.JS to compile ES2015+ files to ES5 using Babel directly from NPM, without vendoring it.}

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|script|js\/babel-plugin-sprockets-commoner-internal\/test)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_dependency "sprockets", ">= 3", "< 4"
  spec.add_dependency "schmooze", "~> 0.1.5"

  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "coffee-script", "~> 2.4"
  spec.add_development_dependency "uglifier", "~> 2.7"
  spec.add_development_dependency "pry", "~> 0.10"
end
