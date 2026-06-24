# frozen_string_literal: true

class CreateRegistrationSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :registration_settings do |t|
      t.boolean :enabled, null: false, default: true
      t.integer :singleton_guard, null: false, default: 0

      t.timestamps
    end

    add_index :registration_settings, :singleton_guard, unique: true
  end
end
