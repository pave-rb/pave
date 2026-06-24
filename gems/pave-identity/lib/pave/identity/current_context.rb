# frozen_string_literal: true

module Pave
  module Identity
    module CurrentContext
      extend ActiveSupport::Concern

      included do
        before_action :set_pave_current_context
      end

      private

      def set_pave_current_context
        Pave::Current.reset

        authenticated_user = warden_user

        return unless authenticated_user

        if impersonating_via_session?
          impersonated_user = find_impersonated_user
          Pave::Current.impersonator = authenticated_user
          Pave::Current.actor = authenticated_user
          Pave::Current.user = impersonated_user || authenticated_user
        else
          Pave::Current.actor = authenticated_user
          Pave::Current.user = authenticated_user
        end
      end

      def warden_user
        return unless defined?(warden)

        warden.authenticate(scope: :user)
      rescue NoMethodError
        nil
      end

      def impersonating_via_session?
        session[:impersonated_user_id].present?
      end

      def find_impersonated_user
        user_id = session[:impersonated_user_id]
        return unless user_id

        Pave::Identity::User.find_by(id: user_id)
      end
    end
  end
end
