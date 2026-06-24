# frozen_string_literal: true

class TenantScopeWhatsappTemplates < ActiveRecord::Migration[8.1]
  class TemplateRecord < ApplicationRecord
    self.table_name = "whatsapp_templates"
  end

  class PhoneNumberRecord < ApplicationRecord
    self.table_name = "whatsapp_phone_numbers"
  end

  class SpaceRecord < ApplicationRecord
    self.table_name = "spaces"
  end

  def up
    add_reference :whatsapp_templates, :space, foreign_key: true, index: true
    add_reference :whatsapp_templates, :whatsapp_phone_number, foreign_key: true, index: true
    add_column :whatsapp_templates, :waba_id, :string
    add_column :whatsapp_templates, :source, :string, null: false, default: "meta_synced"
    add_column :whatsapp_templates, :sync_mode, :string, null: false, default: "read_only"
    add_column :whatsapp_templates, :parameter_schema, :jsonb, null: false, default: {}
    add_column :whatsapp_templates, :supports_bsuid_recipient, :boolean, null: false, default: false
    add_column :whatsapp_templates, :has_request_contact_info_button, :boolean, null: false, default: false

    backfill_existing_templates

    remove_index :whatsapp_templates, name: "idx_whatsapp_templates_identity"
    remove_index :whatsapp_templates, name: "idx_whatsapp_templates_meta_name_locale"
    remove_index :whatsapp_templates, name: "index_whatsapp_templates_on_meta_status"

    add_index :whatsapp_templates,
              [ :space_id, :name, :version, :locale ],
              unique: true,
              name: "idx_whatsapp_templates_space_identity"
    add_index :whatsapp_templates,
              [ :space_id, :meta_template_name, :locale ],
              unique: true,
              name: "idx_whatsapp_templates_space_meta_locale"
    add_index :whatsapp_templates,
              [ :space_id, :meta_status ],
              name: "idx_whatsapp_templates_space_status"
    add_index :whatsapp_templates,
              [ :space_id, :source ],
              name: "idx_whatsapp_templates_space_source"
  end

  def down
    remove_index :whatsapp_templates, name: "idx_whatsapp_templates_space_source"
    remove_index :whatsapp_templates, name: "idx_whatsapp_templates_space_status"
    remove_index :whatsapp_templates, name: "idx_whatsapp_templates_space_meta_locale"
    remove_index :whatsapp_templates, name: "idx_whatsapp_templates_space_identity"

    add_index :whatsapp_templates, [ :name, :version, :locale ],
              unique: true, name: "idx_whatsapp_templates_identity"
    add_index :whatsapp_templates, [ :meta_template_name, :locale ],
              unique: true, name: "idx_whatsapp_templates_meta_name_locale"
    add_index :whatsapp_templates, :meta_status

    remove_column :whatsapp_templates, :has_request_contact_info_button
    remove_column :whatsapp_templates, :supports_bsuid_recipient
    remove_column :whatsapp_templates, :parameter_schema
    remove_column :whatsapp_templates, :sync_mode
    remove_column :whatsapp_templates, :source
    remove_column :whatsapp_templates, :waba_id
    remove_reference :whatsapp_templates, :whatsapp_phone_number, foreign_key: true, index: true
    remove_reference :whatsapp_templates, :space, foreign_key: true, index: true
  end

  private

  def backfill_existing_templates
    TemplateRecord.reset_column_information
    phone_number = anella_internal_phone_number
    return unless phone_number

    TemplateRecord.where(space_id: nil).find_each do |template|
      template.update_columns(
        space_id: phone_number.space_id,
        whatsapp_phone_number_id: phone_number.id,
        waba_id: phone_number.waba_id,
        source: "anella_created",
        sync_mode: "read_write",
        has_request_contact_info_button: request_contact_info_button?(template.buttons),
        updated_at: Time.current
      )
    end
  end

  def anella_internal_phone_number
    space = SpaceRecord.find_by(name: [ "Anella", "Clinica Anella", "Anella Internal", "Anella Operations" ])
    return unless space

    PhoneNumberRecord.find_by(space_id: space.id)
  end

  def request_contact_info_button?(buttons)
    Array(buttons).any? do |button|
      button.to_h["type"].to_s.upcase == "REQUEST_CONTACT_INFO"
    end
  end
end
