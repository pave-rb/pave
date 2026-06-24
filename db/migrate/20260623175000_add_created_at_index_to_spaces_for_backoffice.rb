# frozen_string_literal: true

class AddCreatedAtIndexToSpacesForBackoffice < ActiveRecord::Migration[8.0]
  def change
    add_index :spaces, :created_at unless index_exists?(:spaces, :created_at)
  end
end
