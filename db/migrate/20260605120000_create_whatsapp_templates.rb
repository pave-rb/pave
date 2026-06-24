# frozen_string_literal: true

class CreateWhatsappTemplates < ActiveRecord::Migration[8.0]
  class TemplateRecord < ApplicationRecord
    self.table_name = "whatsapp_templates"
  end

  def change
    create_table :whatsapp_templates do |t|
      t.string :name, null: false
      t.string :version, null: false
      t.string :locale, null: false
      t.string :category, null: false
      t.string :meta_template_name, null: false
      t.text :body, null: false
      t.text :footer, null: false, default: ""
      t.jsonb :variables, null: false, default: []
      t.jsonb :sample_values, null: false, default: {}
      t.jsonb :buttons, null: false, default: []
      t.string :meta_template_id
      t.string :meta_status, null: false, default: "NOT_REGISTERED"
      t.string :meta_category
      t.jsonb :remote_components, null: false, default: []
      t.datetime :last_synced_at
      t.datetime :submitted_at
      t.datetime :approved_at
      t.text :rejected_reason
      t.text :last_error
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :whatsapp_templates, [ :name, :version, :locale ],
              unique: true, name: "idx_whatsapp_templates_identity"
    add_index :whatsapp_templates, [ :meta_template_name, :locale ],
              unique: true, name: "idx_whatsapp_templates_meta_name_locale"
    add_index :whatsapp_templates, :meta_status

    reversible do |dir|
      dir.up { seed_default_templates }
    end
  end

  private

  def seed_default_templates
    TemplateRecord.reset_column_information
    now = Time.current

    TemplateRecord.upsert_all(
      [
        {
          name: "appointment_confirmation",
          version: "v1",
          locale: "pt_BR",
          category: "UTILITY",
          meta_template_name: "appt_confirm_v1_pt_br",
          variables: %w[customer_name business_name date time],
          sample_values: {
            customer_name: "Joao",
            business_name: "Clinica Anella",
            date: "17 de abril de 2026",
            time: "14:00"
          },
          body: <<~BODY.strip,
            Ola {{customer_name}}! Confirmando seu horario em {{business_name}}:
            {{date}} as {{time}}
            Posso confirmar?
          BODY
          buttons: [
            { id: "CONFIRM", text: "Sim, confirmar" },
            { id: "CANCEL", text: "Cancelar" },
            { id: "RESCHEDULE", text: "Remarcar" }
          ],
          footer: "Responda SAIR para nao receber lembretes.",
          created_at: now,
          updated_at: now
        }
      ],
      unique_by: "idx_whatsapp_templates_identity"
    )
  end
end
