# frozen_string_literal: true

module Pave
  class DevSubdomainConstraint
    def initialize(product)
      @product = product
    end

    def matches?(request)
      request.host == "#{@product.dev_subdomain}.localhost"
    end
  end
end
