# frozen_string_literal: true

class Space < ApplicationRecord
  include Schedulable

  attribute :timezone, :string, default: "America/Sao_Paulo"

  belongs_to :owner, class_name: "User", optional: true
  belongs_to :default_inbox_assignee, class_name: "User", optional: true
  has_many :space_memberships, dependent: :destroy
  has_many :users, through: :space_memberships
  has_many :stored_files, as: :attachable, dependent: :destroy, inverse_of: :attachable
  has_one :banner_file,
          -> { where(scope: StoredFile::SPACE_BANNER_SCOPE) },
          as: :attachable,
          class_name: "StoredFile",
          inverse_of: :attachable

  BUSINESS_TYPES = %w[clinic barbershop salon consultancy law_office fitness therapy other].freeze

  validates :name, presence: true
  validates :business_type, inclusion: { in: BUSINESS_TYPES }, allow_nil: true
  validates :slot_duration_minutes, numericality: { only_integer: true, greater_than: 0 }
  validates :timezone, presence: true
  validates :confirmation_lead_hours, presence: true
  validate :confirmation_lead_hours_must_be_supported
  validate :confirmation_quiet_hours_must_be_paired
  validate :default_inbox_assignee_must_be_member
  has_many :customers, dependent: :destroy
  has_many :appointments, dependent: :destroy
  has_many :scheduling_links, dependent: :destroy
  has_many :bookable_resources, dependent: :destroy
  has_one :personalized_scheduling_link, dependent: :destroy
  has_one :crm_public_profile, class_name: "Crm::PublicProfile", dependent: :destroy

  has_many :subscriptions,     class_name: "Billing::Subscription",     dependent: :destroy
  has_one  :subscription,
           -> {
             joins(:billing_product)
               .where(billing_products: { key: Billing::Product::CRM_KEY })
               .includes(:billing_plan)
               .order(Arel.sql("CASE WHEN subscriptions.status <> 4 THEN 0 ELSE 1 END"), created_at: :desc)
           },
           class_name: "Billing::Subscription"
  has_one  :message_credit,    class_name: "Billing::MessageCredit",   dependent: :destroy
  has_many :payments,          class_name: "Billing::Payment",          dependent: :destroy
  has_many :billing_events,    class_name: "Billing::BillingEvent",     dependent: :destroy
  has_many :credit_purchases,  class_name: "Billing::CreditPurchase",   dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :whatsapp_conversations, dependent: :destroy
  has_many :whatsapp_contact_identities, dependent: :destroy
  has_many :whatsapp_templates, dependent: :destroy
  has_one :whatsapp_phone_number, dependent: :destroy
  # business_hours: cached display string; updated by AvailabilitySchedule callback. Read-only.

  def default_locale
    LocaleResolver.space(self)
  end

  def availability_configured?
    availability_schedule.present? &&
      availability_schedule.availability_windows.where.not(opens_at: nil).where.not(closes_at: nil).exists?
  end

  def setup_complete?
    availability_configured? && scheduling_links.any?
  end

  def onboarding_complete?
    completed_onboarding_at.present?
  end

  # Returns array of weekday integers (0=Sunday..6=Saturday) when the space has availability.
  def business_weekdays
    return [] unless availability_schedule

    availability_schedule
      .availability_windows
      .where.not(opens_at: nil)
      .where.not(closes_at: nil)
      .distinct
      .pluck(:weekday)
  end

  DEFAULT_BUSINESS_HOURS = {
    "1" => { "open" => "09:00", "close" => "17:00" },
    "2" => { "open" => "09:00", "close" => "17:00" },
    "3" => { "open" => "09:00", "close" => "17:00" },
    "4" => { "open" => "09:00", "close" => "17:00" },
    "5" => { "open" => "09:00", "close" => "17:00" }
  }.freeze

  def appointment_automation_active?
    appointment_automation_enabled? && demo_automations_allowed? && whatsapp_phone_number.present?
  end

  def demo_automations_allowed?
    subscription&.demo_automations_allowed? != false
  end

  def default_bookable_resource
    Crm::BookableResources.default_for(space: self)
  end

  def within_quiet_hours?(time_in_space_tz)
    return false if confirmation_quiet_hours_start.blank? || confirmation_quiet_hours_end.blank?

    from = confirmation_quiet_hours_start.seconds_since_midnight
    to = confirmation_quiet_hours_end.seconds_since_midnight
    time_of_day = time_in_space_tz.seconds_since_midnight

    if from < to
      (from..to).cover?(time_of_day)
    else
      time_of_day >= from || time_of_day <= to
    end
  end

  private

  def confirmation_lead_hours_must_be_supported
    return if confirmation_lead_hours.blank?
    return if confirmation_lead_hours.all? { |value| value.is_a?(Integer) && value.between?(1, 168) }

    errors.add(:confirmation_lead_hours, :inclusion, message: I18n.t("automation.errors.lead_hours_range"))
  end

  def confirmation_quiet_hours_must_be_paired
    return if confirmation_quiet_hours_start.blank? == confirmation_quiet_hours_end.blank?

    errors.add(:confirmation_quiet_hours_start, :blank) if confirmation_quiet_hours_start.blank?
    errors.add(:confirmation_quiet_hours_end, :blank) if confirmation_quiet_hours_end.blank?
  end

  def default_inbox_assignee_must_be_member
    return if default_inbox_assignee_id.blank?
    return if space_memberships.exists?(user_id: default_inbox_assignee_id)

    errors.add(:default_inbox_assignee, :invalid)
  end
end
