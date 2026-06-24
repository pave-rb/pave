# frozen_string_literal: true

class CreatePaveSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :pave_settings do |t|
      t.string :namespace, null: false
      t.string :key, null: false
      t.text :value
      t.string :value_type, null: false, default: "string"
      t.bigint :updated_by_id
      t.timestamps

      t.index %i[namespace key], unique: true
      t.index :updated_by_id
    end
  end
end
