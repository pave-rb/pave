# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  after_create_commit :deliver_push_later

  validates :title,      presence: true
  validates :body,       presence: true
  validates :event_type, presence: true

  scope :ordered, -> { order(created_at: :desc) }
  scope :recent,  ->(n = 10) { ordered.limit(n) }

  # Returns a hash the controller can pass to url_for to navigate to the
  # related record. Keeps route helpers out of the model.
  def target_path
    case notifiable_type
    when "Appointment"
      { controller: "spaces/appointments", action: "show", id: notifiable_id }
    when "Billing::Subscription"
      { controller: "spaces/billing", action: "show" }
    when "Billing::MessageCredit", "Billing::CreditPurchase"
      { controller: "spaces/credits", action: "show" }
    when "WhatsappConversation"
      { controller: "spaces/inbox", action: "show", id: notifiable_id }
    when "WhatsappPhoneNumber"
      { controller: "spaces/whatsapp_settings", action: "show" }
    end
  end

  private

  def deliver_push_later
    Notifications::DeliverPushNotificationJob.perform_later(id)
  end
end
