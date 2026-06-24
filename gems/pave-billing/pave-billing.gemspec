# frozen_string_literal: true

require_relative "lib/pave/billing/version"

Gem::Specification.new do |spec|
  spec.name = "pave-billing"
  spec.version = Pave::Billing::VERSION
  spec.authors = [ "Pave" ]
  spec.summary = "Pave billing runtime package."
  spec.files = Dir["lib/**/*.rb", "README.md"]
  spec.require_paths = [ "lib" ]
  spec.required_ruby_version = ">= 3.4.0"

  spec.add_dependency "rails", ">= 8.0"
  spec.add_dependency "pave-core", "= #{Pave::Billing::VERSION}"
  spec.add_dependency "pave-tenancy", "= #{Pave::Billing::VERSION}"
  spec.add_dependency "pave-audit", "= #{Pave::Billing::VERSION}"
end
