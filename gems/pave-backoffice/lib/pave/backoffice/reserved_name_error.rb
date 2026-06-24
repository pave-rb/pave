# frozen_string_literal: true

module Pave
  module Backoffice
    class ReservedNameError < StandardError
      RESERVED_SLUGS = %w[users audit settings credentials health platform].freeze

      def initialize(slug)
        super("Product slug '#{slug}' is reserved. Cannot use '#{slug}' as a product key because it conflicts with platform routes under /admin/. Reserved slugs: #{RESERVED_SLUGS.join(', ')}")
      end
    end
  end
end
