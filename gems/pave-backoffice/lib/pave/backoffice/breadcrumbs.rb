# frozen_string_literal: true

module Pave
  module Backoffice
    class Breadcrumbs
      Crumb = Data.define(:title, :route)

      include Enumerable

      def initialize
        @crumbs = []
      end

      def add(title, route: nil)
        @crumbs << Crumb.new(title.to_s, route)
      end

      def each(&block)
        @crumbs.each(&block)
      end

      def to_a
        @crumbs.dup
      end
    end
  end
end
