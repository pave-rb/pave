# frozen_string_literal: true

class CreateWhatsappContactIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :whatsapp_contact_identities do |t|
      t.references :space, null: false, foreign_key: true
      t.references :customer, foreign_key: true
      t.references :whatsapp_phone_number, null: false, foreign_key: true
      t.string :waba_id, null: false
      t.string :business_portfolio_id
      t.string :user_id
      t.string :parent_user_id
      t.string :wa_id
      t.string :phone
      t.string :username
      t.string :profile_name
      t.datetime :first_seen_at, null: false
      t.datetime :last_seen_at, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :whatsapp_contact_identities,
              [ :space_id, :whatsapp_phone_number_id, :user_id ],
              unique: true,
              where: "user_id IS NOT NULL",
              name: "idx_whatsapp_contact_identities_on_scoped_user_id"
    add_index :whatsapp_contact_identities,
              [ :space_id, :whatsapp_phone_number_id, :parent_user_id ],
              unique: true,
              where: "parent_user_id IS NOT NULL",
              name: "idx_whatsapp_contact_identities_on_scoped_parent_user_id"
    add_index :whatsapp_contact_identities,
              [ :space_id, :whatsapp_phone_number_id, :wa_id ],
              unique: true,
              where: "wa_id IS NOT NULL",
              name: "idx_whatsapp_contact_identities_on_scoped_wa_id"
    add_index :whatsapp_contact_identities, [ :space_id, :customer_id ]
    add_index :whatsapp_contact_identities,
              [ :space_id, :phone ],
              where: "phone IS NOT NULL",
              name: "idx_whatsapp_contact_identities_on_space_phone"
  end
end
