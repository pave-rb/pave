# frozen_string_literal: true

module Pave
  module Backoffice
    class Panel
      PANEL_FIELDS = %i[name label controller route_block position source
                        source_package description status diagnostics
                        route capability group icon].freeze

      attr_reader(*PANEL_FIELDS)

      def initialize(name:, label:, controller: nil, route_block: nil, position: 99,
                     source: nil, source_package: nil, description: nil,
                     status: nil, diagnostics: nil,
                     route: nil, capability: nil, group: nil, icon: nil)
        @name = name.to_s.to_sym
        @label = label
        @controller = controller
        @route_block = route_block
        @position = Integer(position)
        @source = source
        @source_package = source_package
        @description = description
        @status = status
        @diagnostics = diagnostics
        @route = route
        @capability = capability
        @group = group
        @icon = icon
        freeze
      end

      def slug
        name.to_s.dasherize
      end

      def key
        name
      end

      def title
        label
      end

      def route_name
        route.to_s unless route.to_s.start_with?("/")
      end

      def path(view_context)
        return route if route.to_s.start_with?("/")

        view_context.public_send("#{route}_path")
      rescue NoMethodError
        "#"
      end
    end
  end
end
