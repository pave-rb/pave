# frozen_string_literal: true

# This file wires host-app-level Pavê extensions.
# Core product/product_registry and module-level methods are now defined in pave-core.

require "pave/core"
require "pave/backoffice"

require_relative "pave/backoffice_registry"
require_relative "pave/product_boot"
require_relative "pave/dev_subdomain_constraint"
