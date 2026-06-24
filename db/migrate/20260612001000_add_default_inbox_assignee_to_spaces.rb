# frozen_string_literal: true

class AddDefaultInboxAssigneeToSpaces < ActiveRecord::Migration[8.1]
  def change
    add_reference :spaces, :default_inbox_assignee, foreign_key: { to_table: :users }, index: true
  end
end
