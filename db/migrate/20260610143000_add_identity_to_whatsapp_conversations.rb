# frozen_string_literal: true

class AddIdentityToWhatsappConversations < ActiveRecord::Migration[8.1]
  def change
    change_column_null :whatsapp_conversations, :wa_id, true
    change_column_null :whatsapp_conversations, :customer_phone, true

    add_reference :whatsapp_conversations, :whatsapp_phone_number, foreign_key: true
    add_reference :whatsapp_conversations, :whatsapp_contact_identity, foreign_key: true
    add_column :whatsapp_conversations, :external_user_id, :string
    add_column :whatsapp_conversations, :external_user_id_type, :string

    add_index :whatsapp_conversations,
              [ :space_id, :whatsapp_phone_number_id, :external_user_id_type, :external_user_id ],
              unique: true,
              where: "external_user_id IS NOT NULL",
              name: "idx_whatsapp_conversations_on_scoped_external_user"
  end
end
