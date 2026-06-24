class RemoveReadFromNotifications < ActiveRecord::Migration[8.0]
  def change
    remove_index :notifications, name: "index_notifications_on_user_id_and_read"
    remove_column :notifications, :read, :boolean, default: false
  end
end
