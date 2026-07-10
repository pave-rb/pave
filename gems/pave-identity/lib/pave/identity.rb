# frozen_string_literal: true

require "pave/identity/version"
require "pave/identity/engine"
require "pave/identity/impersonation"
require "pave/identity/webauthn"

module Pave
  module Identity
    class << self
      def current_user
        Pave::Current.user
      end

      def current_actor
        Pave::Current.actor || Pave::Current.user
      end

      def current_impersonator
        Pave::Current.impersonator
      end
    end
  end
end
