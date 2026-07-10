# frozen_string_literal: true

module Pave
  module Backoffice
    class ProfilesController < BaseController
      before_action :set_user

      def edit
      end

      def update
        if @user.update(profile_params)
          redirect_to edit_profile_path, notice: "Profile updated.", status: :see_other
        else
          render :edit, status: :unprocessable_entity
        end
      end

      private

      def set_user
        @user = current_admin
      end

      def profile_params
        params.require(:user).permit(:name)
      end
    end
  end
end
