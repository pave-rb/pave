# frozen_string_literal: true

require_relative "lib/pave/rails/version"

Gem::Specification.new do |spec|
  spec.name = "pave-rails"
  spec.version = Pave::Rails::VERSION
  spec.authors = [ "Pave" ]
  spec.summary = "Pavê Rails integration gem."
  spec.description = "Rails engine and Railtie that wires Pavê runtime into a host Rails app."
  spec.license = "MIT"
  spec.homepage = "https://github.com/pave-rb/pave"
  spec.files = Dir["lib/**/*.rb", "README.md"]
  spec.require_paths = [ "lib" ]
  spec.required_ruby_version = ">= 3.4.0"

  spec.metadata = {
    "source_code_uri" => "https://github.com/pave-rb/pave",
    "changelog_uri" => "https://github.com/pave-rb/pave/blob/main/CHANGELOG.md"
  }

  spec.add_dependency "rails", ">= 8.0"
  spec.add_dependency "pave-core", "= #{Pave::Rails::VERSION}"
end
