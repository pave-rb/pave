# frozen_string_literal: true

module Pave
  module Backoffice
    class Navigation
      def initialize(panels:, authorizer: nil)
        @panels = panels
        @authorizer = authorizer || ->(_panel) { true }
      end

      def panels
        @panels.select { |panel| @authorizer.call(panel) }
      end

      def grouped
        panels.group_by { |panel| panel.respond_to?(:group) ? panel.group || :default : :default }
      end
    end
  end
end
