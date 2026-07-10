# frozen_string_literal: true

module Pave
  module Backoffice
    module ProfileSecurity
      class PasswordsController < BaseController
        def update
          if @user.update_with_password(password_params)
            redirect_to profile_security_path, notice: t("profiles.security.password.updated"), status: :see_other
          else
            load_security_overview
            render "pave/backoffice/profile_security/show", status: :unprocessable_entity
          end
        end

        private

        def password_params
          params.require(:user).permit(:current_password, :password, :password_confirmation)
        end
      end
    end
  end
end
