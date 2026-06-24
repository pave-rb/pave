class AddPushNotificationPreferencesToUserPreferences < ActiveRecord::Migration[8.0]
  def change
    add_column :user_preferences, :push_notifications_enabled, :boolean, null: false, default: false
    add_column :user_preferences, :push_notifications_permission, :string, null: false, default: "default"
    add_column :user_preferences, :push_notifications_decided_at, :datetime
    add_column :user_preferences, :push_notifications_enabled_at, :datetime
    add_column :user_preferences, :push_notifications_disabled_at, :datetime
  end
end
