# frozen_string_literal: true

class PushNotificationPreferencesController < ApplicationController
  before_action :authenticate_user!

  def update
    preference = current_user.user_preference || current_user.create_user_preference!(locale: I18n.default_locale.to_s)
    enabled = ActiveModel::Type::Boolean.new.cast(params[:enabled])
    permission = params[:permission].presence || "default"

    if enabled && permission == "granted"
      preference.enable_push_notifications!(permission: permission)
    elsif enabled
      preference.record_push_notification_permission!(permission: permission)
    else
      preference.disable_push_notifications!(permission: permission)
    end

    render json: {
      push_notifications_enabled: preference.push_notifications_enabled?,
      push_notifications_permission: preference.push_notifications_permission
    }
  end
end
