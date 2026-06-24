# frozen_string_literal: true

require_relative "../pave-core/lib/pave/version"

Gem::Specification.new do |spec|
  spec.name = "pave"
  spec.version = Pave::VERSION
  spec.authors = [ "Pave" ]
  spec.summary = "Pavê runtime — the gem most users install."
  spec.description = "Meta-gem that depends on all default Pavê runtime gems."
  spec.license = "MIT"
  spec.homepage = "https://github.com/pave-rb/pave"
  spec.files = Dir["lib/**/*.rb", "exe/**/*", "README.md"]
  spec.bindir = "exe"
  spec.executables = [ "pave" ]
  spec.require_paths = [ "lib" ]
  spec.required_ruby_version = ">= 3.4.0"

  spec.metadata = {
    "source_code_uri" => "https://github.com/pave-rb/pave",
    "changelog_uri" => "https://github.com/pave-rb/pave/blob/main/CHANGELOG.md"
  }

  spec.add_dependency "pave-core", "= #{Pave::VERSION}"
  spec.add_dependency "pave-rails", "= #{Pave::VERSION}"
  spec.add_dependency "pave-tenancy", "= #{Pave::VERSION}"
  spec.add_dependency "pave-identity", "= #{Pave::VERSION}"
  spec.add_dependency "pave-audit", "= #{Pave::VERSION}"
  spec.add_dependency "pave-billing", "= #{Pave::VERSION}"
  spec.add_dependency "pave-backoffice", "= #{Pave::VERSION}"
end
