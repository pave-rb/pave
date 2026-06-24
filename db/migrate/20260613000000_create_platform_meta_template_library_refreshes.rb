# frozen_string_literal: true

class CreatePlatformMetaTemplateLibraryRefreshes < ActiveRecord::Migration[8.0]
  def change
    create_table :platform_meta_template_library_refreshes do |t|
      t.string :locale, null: false
      t.string :status, null: false
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.integer :refreshed_count, default: 0, null: false
      t.string :error_code
      t.text :error_message
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end

    add_index :platform_meta_template_library_refreshes, [ :locale, :status, :finished_at ], name: "idx_platform_meta_template_refresh_status"
  end
end
