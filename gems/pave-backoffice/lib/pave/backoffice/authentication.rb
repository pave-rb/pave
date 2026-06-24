# frozen_string_literal: true

module Pave
  module Backoffice
    module Authentication
      extend ActiveSupport::Concern

      SESSION_KEY = :pave_backoffice_admin_id
      RETURN_TO_KEY = :pave_backoffice_return_to

      included do
        helper_method :current_backoffice_admin, :backoffice_admin_signed_in?
      end

      private

      def current_backoffice_admin
        return @current_backoffice_admin if defined?(@current_backoffice_admin)

        admin_id = session[SESSION_KEY]
        return nil unless admin_id

        @current_backoffice_admin = User.find_by(id: admin_id)
      end

      def backoffice_admin_signed_in?
        current_backoffice_admin.present?
      end

      def authenticate_backoffice_admin!
        return if backoffice_admin_signed_in?

        store_backoffice_return_location
        redirect_to pave_backoffice.sign_in_path
      end

      def sign_in_backoffice_admin(user)
        session[SESSION_KEY] = user.id
        @current_backoffice_admin = user
      end

      def sign_out_backoffice_admin!
        session.delete(SESSION_KEY)
        @current_backoffice_admin = nil
      end

      def store_backoffice_return_location
        session[RETURN_TO_KEY] = request.fullpath unless request.fullpath == pave_backoffice.sign_in_path
      end

      def backoffice_return_location
        session.delete(RETURN_TO_KEY) || pave_backoffice.dashboard_path
      end
    end
  end
end
