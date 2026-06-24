# frozen_string_literal: true

class RemoveOptOutWhatsappTemplate < ActiveRecord::Migration[8.0]
  class TemplateRecord < ApplicationRecord
    self.table_name = "whatsapp_templates"
  end

  def up
    TemplateRecord.where(name: "opt_out_confirmation", locale: "pt_BR").delete_all
  end

  def down
    # Intentionally left blank; the opt-out template was removed because its Meta
    # definition is invalid and should not be restored automatically.
  end
end
