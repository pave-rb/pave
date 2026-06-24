# frozen_string_literal: true

require "pave/tenancy/version"
require "pave/tenancy/engine"

module Pave
  module Tenancy
    class << self
      def with_space(space)
        previous = Pave::Current.space
        Pave::Current.space = space
        yield
      ensure
        Pave::Current.space = previous
      end

      def current_space
        Pave::Current.space
      end

      def space_required!
        raise Pave::Error, "No current space set" unless Pave::Current.space
      end

      def assert_same_space!(record, space)
        return if record.respond_to?(:space_id) && record.space_id == space.id

        raise Pave::Error, "Record does not belong to the current space"
      end
    end
  end
end
