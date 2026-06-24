# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "pave"
  spec.version = "0.1.0"
  spec.authors = [ "Pave" ]
  spec.summary = "Pavê runtime — the gem most users install."
  spec.description = "Meta-gem that depends on all default Pavê runtime gems."
  spec.files = Dir["lib/**/*.rb", "exe/**/*", "README.md"]
  spec.bindir = "exe"
  spec.executables = [ "pave" ]
  spec.require_paths = [ "lib" ]
  spec.required_ruby_version = ">= 3.4.0"

  spec.add_dependency "pave-core", "= 0.1.0"
  spec.add_dependency "pave-rails", "= 0.1.0"
  spec.add_dependency "pave-tenancy", "= 0.1.0"
  spec.add_dependency "pave-identity", "= 0.1.0"
  spec.add_dependency "pave-audit", "= 0.1.0"
  spec.add_dependency "pave-backoffice", "= 0.1.0"
end
