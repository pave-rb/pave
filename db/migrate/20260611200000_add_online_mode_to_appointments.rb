# frozen_string_literal: true

class AddOnlineModeToAppointments < ActiveRecord::Migration[8.1]
  def change
    add_column :appointments, :appointment_mode, :integer, null: false, default: 0
    add_column :appointments, :meeting_url, :string
    add_column :appointments, :meeting_instructions, :text

    add_index :appointments, [ :space_id, :appointment_mode ]
  end
end
