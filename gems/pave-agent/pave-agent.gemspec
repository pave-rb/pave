# frozen_string_literal: true

require_relative "lib/pave/agent/version"

Gem::Specification.new do |spec|
  spec.name = "pave-agent"
  spec.version = Pave::Agent::VERSION
  spec.authors = [ "Pave" ]
  spec.summary = "Pavê agent context generation (planned)."
  spec.description = "Agent context generation, workflow templates, and bin/pave context command. Not yet implemented."
  spec.license = "MIT"
  spec.homepage = "https://github.com/pave-rb/pave"
  spec.files = Dir["lib/**/*.rb", "README.md"]
  spec.require_paths = [ "lib" ]
  spec.required_ruby_version = ">= 3.4.0"

  spec.metadata = {
    "source_code_uri" => "https://github.com/pave-rb/pave",
    "changelog_uri" => "https://github.com/pave-rb/pave/blob/main/CHANGELOG.md"
  }

  spec.add_dependency "pave-core", "= #{Pave::Agent::VERSION}"
end
