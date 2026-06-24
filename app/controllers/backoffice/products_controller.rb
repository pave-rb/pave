# frozen_string_literal: true

module Backoffice
  class ProductsController < Backoffice::BaseController
    def index
      @products = Pave.backoffice.products.map { |product| product_card(product) }
    end

    private

    def product_card(product)
      {
        name: translated_product_attribute(product, :name, product.label),
        description: translated_product_attribute(product, :description, product.description),
        status: translated_product_attribute(product, :status, product.status),
        path: product.path
      }
    end

    def translated_product_attribute(product, attribute, default)
      return default if product.i18n_key.blank?

      t("#{product.i18n_key}.#{attribute}", default: default)
    end
  end
end
