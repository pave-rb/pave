# frozen_string_literal: true

require_relative "lib/pave/backoffice/version"

Gem::Specification.new do |spec|
  spec.name = "pave-backoffice"
  spec.version = Pave::Backoffice::VERSION
  spec.authors = [ "Pave" ]
  spec.summary = "Pave backoffice runtime package."
  spec.files = Dir["lib/**/*.{rb,erb}", "app/**/*.{rb,erb,js}", "config/**/*.rb", "README.md"]
  spec.require_paths = [ "lib" ]
  spec.required_ruby_version = ">= 3.4.0"

  spec.add_dependency "rails", ">= 8.0"
  spec.add_dependency "pave-core", "= #{Pave::Backoffice::VERSION}"
  spec.add_dependency "pave-tenancy", "= #{Pave::Backoffice::VERSION}"
  spec.add_dependency "pave-audit", "= #{Pave::Backoffice::VERSION}"
  spec.add_dependency "pave-identity", "= #{Pave::Backoffice::VERSION}"
  spec.add_dependency "pave-billing", "= #{Pave::Backoffice::VERSION}"
end
