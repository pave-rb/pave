# frozen_string_literal: true

class CreateWhatsappTemplateBlueprints < ActiveRecord::Migration[8.1]
  DEFAULT_APPOINTMENT_CONFIRMATION = {
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
    footer: "Responda SAIR para nao receber lembretes."
  }.freeze

  class BlueprintRecord < ApplicationRecord
    self.table_name = "whatsapp_template_blueprints"
  end

  class TemplateRecord < ApplicationRecord
    self.table_name = "whatsapp_templates"
  end

  def up
    create_table :whatsapp_template_blueprints do |t|
      t.string :name, null: false
      t.string :version, null: false
      t.string :locale, null: false
      t.string :category, null: false
      t.text :body, null: false
      t.text :footer, null: false, default: ""
      t.jsonb :variables, null: false, default: []
      t.jsonb :sample_values, null: false, default: {}
      t.jsonb :buttons, null: false, default: []
      t.jsonb :components, null: false, default: []
      t.jsonb :metadata, null: false, default: {}
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :whatsapp_template_blueprints,
              [ :name, :version, :locale ],
              unique: true,
              name: "idx_whatsapp_template_blueprints_identity"
    add_index :whatsapp_template_blueprints, :active

    migrate_legacy_starter_templates
    seed_default_starter_blueprint
    delete_legacy_starter_templates
  end

  def down
    restore_legacy_starter_templates
    drop_table :whatsapp_template_blueprints
  end

  private

  def migrate_legacy_starter_templates
    BlueprintRecord.reset_column_information
    TemplateRecord.reset_column_information

    legacy_starter_templates.find_each do |template|
      blueprint = BlueprintRecord.find_or_initialize_by(
        name: template.name,
        version: template.version,
        locale: template.locale
      )
      blueprint.assign_attributes(blueprint_attributes_from_template(template))
      blueprint.save!
    end
  end

  def seed_default_starter_blueprint
    BlueprintRecord.reset_column_information
    BlueprintRecord.find_or_create_by!(
      name: DEFAULT_APPOINTMENT_CONFIRMATION.fetch(:name),
      version: DEFAULT_APPOINTMENT_CONFIRMATION.fetch(:version),
      locale: DEFAULT_APPOINTMENT_CONFIRMATION.fetch(:locale)
    ) do |blueprint|
      blueprint.assign_attributes(default_blueprint_attributes)
    end
  end

  def delete_legacy_starter_templates
    legacy_starter_templates.delete_all
  end

  def restore_legacy_starter_templates
    BlueprintRecord.reset_column_information
    TemplateRecord.reset_column_information

    BlueprintRecord.find_each do |blueprint|
      next if TemplateRecord.where(space_id: nil, name: blueprint.name, version: blueprint.version, locale: blueprint.locale).exists?

      now = Time.current
      TemplateRecord.create!(
        name: blueprint.name,
        version: blueprint.version,
        locale: blueprint.locale,
        category: blueprint.category,
        meta_template_name: blueprint.metadata.to_h["meta_template_name"].presence || generated_meta_template_name(blueprint),
        body: blueprint.body,
        footer: blueprint.footer,
        variables: blueprint.variables,
        sample_values: blueprint.sample_values,
        buttons: blueprint.buttons,
        remote_components: blueprint.components,
        metadata: blueprint.metadata,
        source: "meta_synced",
        sync_mode: "read_only",
        meta_status: "NOT_REGISTERED",
        created_at: now,
        updated_at: now
      )
    end
  end

  def legacy_starter_templates
    TemplateRecord.where(space_id: nil)
  end

  def blueprint_attributes_from_template(template)
    {
      category: template.category,
      body: template.body,
      footer: template.footer,
      variables: template.variables,
      sample_values: template.sample_values,
      buttons: template.buttons,
      components: template.remote_components,
      metadata: template.metadata.to_h.merge(
        "meta_template_name" => template.meta_template_name,
        "source_whatsapp_template_id" => template.id
      ),
      active: true
    }
  end

  def default_blueprint_attributes
    {
      category: DEFAULT_APPOINTMENT_CONFIRMATION.fetch(:category),
      body: DEFAULT_APPOINTMENT_CONFIRMATION.fetch(:body),
      footer: DEFAULT_APPOINTMENT_CONFIRMATION.fetch(:footer),
      variables: DEFAULT_APPOINTMENT_CONFIRMATION.fetch(:variables),
      sample_values: DEFAULT_APPOINTMENT_CONFIRMATION.fetch(:sample_values),
      buttons: DEFAULT_APPOINTMENT_CONFIRMATION.fetch(:buttons),
      components: [],
      metadata: {
        "meta_template_name" => DEFAULT_APPOINTMENT_CONFIRMATION.fetch(:meta_template_name)
      },
      active: true
    }
  end

  def generated_meta_template_name(record)
    [
      record.name,
      record.version,
      record.locale
    ].join("_").downcase.gsub(/[^a-z0-9_]+/, "_").squeeze("_").delete_prefix("_").delete_suffix("_")
  end
end
