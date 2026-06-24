# frozen_string_literal: true

require_relative "lib/pave/core/version"

Gem::Specification.new do |spec|
  spec.name = "pave-core"
  spec.version = Pave::Core::VERSION
  spec.authors = [ "Pave" ]
  spec.summary = "Pave core runtime package."
  spec.license = "MIT"
  spec.homepage = "https://github.com/pave-rb/pave"
  spec.files = Dir["lib/**/*.rb", "README.md"]
  spec.require_paths = [ "lib" ]
  spec.required_ruby_version = ">= 3.4.0"

  spec.metadata = {
    "source_code_uri" => "https://github.com/pave-rb/pave",
    "changelog_uri" => "https://github.com/pave-rb/pave/blob/main/CHANGELOG.md"
  }
end
