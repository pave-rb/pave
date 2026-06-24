# frozen_string_literal: true

class UserPreference < ApplicationRecord
  PUSH_NOTIFICATION_PERMISSIONS = %w[default granted denied unsupported].freeze

  belongs_to :user

  validates :locale, presence: true, inclusion: { in: I18n.available_locales.map(&:to_s) }
  validates :push_notifications_enabled, inclusion: { in: [ true, false ] }
  validates :push_notifications_permission, presence: true, inclusion: { in: PUSH_NOTIFICATION_PERMISSIONS }

  before_validation :set_default_locale, on: :create
  before_validation :set_default_push_notification_permission

  def enable_push_notifications!(permission: "granted")
    update!(
      push_notifications_enabled: true,
      push_notifications_permission: normalize_push_notification_permission(permission),
      push_notifications_enabled_at: Time.current,
      push_notifications_disabled_at: nil,
      push_notifications_decided_at: Time.current
    )
  end

  def disable_push_notifications!(permission: nil)
    update!(
      push_notifications_enabled: false,
      push_notifications_permission: normalize_push_notification_permission(permission || push_notifications_permission),
      push_notifications_disabled_at: Time.current,
      push_notifications_decided_at: Time.current
    )
  end

  def record_push_notification_permission!(permission:)
    normalized_permission = normalize_push_notification_permission(permission)

    update!(
      push_notifications_enabled: normalized_permission == "granted" && push_notifications_enabled?,
      push_notifications_permission: normalized_permission,
      push_notifications_decided_at: Time.current
    )
  end

  private

  def set_default_locale
    self.locale ||= I18n.default_locale.to_s
  end

  def set_default_push_notification_permission
    self.push_notifications_permission ||= "default"
  end

  def normalize_push_notification_permission(permission)
    permission = permission.to_s
    return permission if PUSH_NOTIFICATION_PERMISSIONS.include?(permission)

    "default"
  end
end
