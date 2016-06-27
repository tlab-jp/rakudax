# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rakudax/version'

Gem::Specification.new do |spec|
  spec.name          = "rakudax"
  spec.version       = Rakudax::VERSION
  spec.authors       = ["metalels", "bon10"]
  spec.email         = ["metalels86@gmail.com"]

  spec.summary       = %q{Data migration tool using (ruby)Active Record.}
  spec.description   = %q{Data migration tool using (ruby)Active Record.}
  spec.homepage      = "https://github.com/tlab-jp/rakudax"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = ["rakudax"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'activerecord', "~> 4.0"
  spec.add_development_dependency 'activesupport', "~> 4.0"
  spec.add_development_dependency 'settingslogic', "~> 2.0"
end
