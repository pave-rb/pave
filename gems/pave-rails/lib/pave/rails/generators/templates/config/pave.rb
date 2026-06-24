# frozen_string_literal: true

# Pavê runtime configuration for this host app.
#
# Products are registered here. Each product is a domain package
# loaded by the runtime at boot.

Pave.configure do |config|
  # Register products:
  # config.product :my_product, path: "products/my_product"
  #
  # Register plugins:
  # config.plugin :my_plugin
end
