# frozen_string_literal: true

module Pave
  module Tenancy
    class BaseController < ActionController::Base
      around_action :with_current_space

      private

      def with_current_space
        space = resolve_current_space
        Pave::Tenancy.with_space(space) { yield }
      end

      def resolve_current_space
        nil
      end

      def current_actor
        nil
      end
    end
  end
end
