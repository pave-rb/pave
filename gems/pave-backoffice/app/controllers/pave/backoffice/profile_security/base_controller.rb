# frozen_string_literal: true

module Pave
  module Backoffice
    module ProfileSecurity
      class BaseController < Pave::Backoffice::BaseController
        before_action :set_user

        private

        def set_user
          @user = current_admin
        end

        def load_security_overview
          @passkeys = @user.user_passkeys.where(rp_id: current_webauthn.rp_id).order(created_at: :desc)
          @active_recovery_codes_count = @user.user_recovery_codes.active.count
        end

        def current_webauthn
          @current_webauthn ||= Pave::Identity::Webauthn.relying_party_for(request)
        end
      end
    end
  end
end
