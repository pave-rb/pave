# frozen_string_literal: true

module Pave
  module Backoffice
    module ProductConfigLoader
      CONFIG_PATH = "config/backoffice.rb"

      class << self
        def load_all(products: Pave.products)
          products.each { |product| load_product(product) }
        end

        def load_product(product)
          path = product.root.join(CONFIG_PATH)
          return false unless path.file?

          load path.to_s
          true
        end
      end
    end
  end
end
