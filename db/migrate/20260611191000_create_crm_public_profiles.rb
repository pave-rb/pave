# frozen_string_literal: true

class CreateCrmPublicProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :crm_public_profiles do |t|
      t.references :space, null: false, foreign_key: true, index: { unique: true }
      t.string :slug
      t.string :display_name, null: false
      t.string :business_type
      t.text :address
      t.string :phone
      t.string :email
      t.string :instagram_url
      t.string :facebook_url
      t.text :booking_success_message
      t.datetime :published_at

      t.timestamps
    end

    add_index :crm_public_profiles, :slug, unique: true, where: "slug IS NOT NULL"

    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          INSERT INTO crm_public_profiles (
            space_id,
            slug,
            display_name,
            business_type,
            address,
            phone,
            email,
            instagram_url,
            facebook_url,
            booking_success_message,
            published_at,
            created_at,
            updated_at
          )
          SELECT
            spaces.id,
            personalized_scheduling_links.slug,
            COALESCE(NULLIF(spaces.name, ''), 'Workspace'),
            spaces.business_type,
            spaces.address,
            spaces.phone,
            spaces.email,
            spaces.instagram_url,
            spaces.facebook_url,
            spaces.booking_success_message,
            CASE
              WHEN personalized_scheduling_links.slug IS NULL THEN NULL
              ELSE CURRENT_TIMESTAMP
            END,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
          FROM spaces
          LEFT JOIN personalized_scheduling_links
            ON personalized_scheduling_links.space_id = spaces.id
        SQL
      end
    end
  end
end
