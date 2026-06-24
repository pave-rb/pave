# frozen_string_literal: true

class AddAppointmentReminderToWhatsappMessages < ActiveRecord::Migration[8.0]
  def change
    add_reference :whatsapp_messages, :appointment_reminder, foreign_key: true, index: true, null: true
  end
end
