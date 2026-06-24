# frozen_string_literal: true

require_relative "lib/pave/audit/version"

Gem::Specification.new do |spec|
  spec.name = "pave-audit"
  spec.version = Pave::Audit::VERSION
  spec.authors = [ "Pave" ]
  spec.summary = "Pave audit runtime package."
  spec.files = Dir["lib/**/*.rb", "README.md"]
  spec.require_paths = [ "lib" ]
  spec.required_ruby_version = ">= 3.4.0"

  spec.add_dependency "rails", ">= 8.0"
  spec.add_dependency "pave-core", "= #{Pave::Audit::VERSION}"
  spec.add_dependency "pave-tenancy", "= #{Pave::Audit::VERSION}"
end
