# frozen_string_literal: true

require_relative "lib/pave/tenancy/version"

Gem::Specification.new do |spec|
  spec.name = "pave-tenancy"
  spec.version = Pave::Tenancy::VERSION
  spec.authors = [ "Pave" ]
  spec.summary = "Pave tenancy runtime package."
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
  spec.add_dependency "pave-core", "= #{Pave::Tenancy::VERSION}"
end
