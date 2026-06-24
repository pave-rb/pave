# frozen_string_literal: true

class CreateBookableResources < ActiveRecord::Migration[8.1]
  def change
    create_table :bookable_resources do |t|
      t.references :space, null: false, foreign_key: true
      t.references :space_membership, null: true, foreign_key: true
      t.string :resource_type, null: false, default: "generic"
      t.string :name, null: false
      t.string :color
      t.boolean :active, null: false, default: true
      t.boolean :default_resource, null: false, default: false
      t.integer :default_duration_minutes
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :bookable_resources, [ :space_id, :active ]
    add_index :bookable_resources, [ :space_id, :space_membership_id ]
    add_index :bookable_resources,
              :space_id,
              unique: true,
              where: "default_resource = true",
              name: "index_bookable_resources_one_default_per_space"

    add_reference :appointments, :bookable_resource, foreign_key: true
    add_index :appointments, [ :space_id, :bookable_resource_id ]

    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          INSERT INTO bookable_resources (
            space_id,
            resource_type,
            name,
            active,
            default_resource,
            default_duration_minutes,
            metadata,
            created_at,
            updated_at
          )
          SELECT
            spaces.id,
            'generic',
            COALESCE(NULLIF(spaces.name, ''), 'Default resource'),
            true,
            true,
            spaces.slot_duration_minutes,
            '{}'::jsonb,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
          FROM spaces
        SQL

        execute <<~SQL.squish
          UPDATE appointments
          SET bookable_resource_id = bookable_resources.id
          FROM bookable_resources
          WHERE bookable_resources.space_id = appointments.space_id
            AND bookable_resources.default_resource = true
            AND appointments.bookable_resource_id IS NULL
        SQL
      end
    end
  end
end
