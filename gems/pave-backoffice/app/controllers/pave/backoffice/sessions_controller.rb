# frozen_string_literal: true

module Pave
  module Backoffice
    class SessionsController < ActionController::Base
      include Pave::Backoffice::Authentication

      layout "pave/backoffice/auth"
      helper Pave::Backoffice::UiHelper

      def new
        redirect_to pave_backoffice.dashboard_path if backoffice_admin_signed_in?
      end

      def create
        admin = User.find_by(email: params[:email]&.downcase&.strip)

        if admin && admin.valid_password?(params[:password])
          if admin.super_admin?
            if admin.mfa_required?
              session[:pave_backoffice_admin_mfa_user_id] = admin.id
              redirect_to mfa_challenge_path
            else
              sign_in_backoffice_admin(admin)
              redirect_to backoffice_return_location, notice: "Signed in to backoffice."
            end
          else
            flash.now[:alert] = "This account does not have platform backoffice access."
            render :new, status: :unprocessable_entity
          end
        else
          flash.now[:alert] = "Invalid email or password."
          render :new, status: :unprocessable_entity
        end
      end

      def destroy
        sign_out_backoffice_admin!
        redirect_to pave_backoffice.sign_in_path, notice: "Signed out of backoffice."
      end
    end
  end
end
