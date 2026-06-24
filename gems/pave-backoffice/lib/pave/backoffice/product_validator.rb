# frozen_string_literal: true

module Pave
  module Backoffice
    class ProductValidator
      RESERVED_SLUGS = Pave::Backoffice::ReservedNameError::RESERVED_SLUGS

      def self.validate!
        Pave.products.each do |product|
          slug = product.key.to_s
          if RESERVED_SLUGS.include?(slug)
            raise ReservedNameError.new(slug)
          end
        end
      end
    end
  end
end
