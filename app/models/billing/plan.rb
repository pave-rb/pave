# frozen_string_literal: true

module Billing
  class Plan < ApplicationRecord
    self.table_name = "billing_plans"

    KNOWN_FEATURES = %w[
      personalized_booking_page
      custom_appointment_policies
      whatsapp_included_quota
      priority_support
    ].freeze

    belongs_to :billing_product,
               class_name: "Billing::Product",
               inverse_of: :plans

    validates :billing_product, presence: true
    validates :slug,        presence: true,
                            uniqueness: { scope: :billing_product_id },
                            format: { with: /\A[a-z0-9_]+\z/ }
    validates :name,        presence: true
    validates :price_cents, presence: true,
                            numericality: { greater_than_or_equal_to: 0 }
    validates :position,    presence: true
    validates :trial_default,
              uniqueness: { scope: :billing_product_id, conditions: -> { where(trial_default: true) } },
              if: :trial_default?

    scope :for_product, ->(product = Billing::Product.crm) { where(billing_product: product) }
    scope :for_product_key, lambda { |key|
      joins(:billing_product).where(billing_products: { key: key })
    }
    scope :active,  -> { where(active: true) }
    scope :visible, ->(product = Billing::Product.crm) { for_product(product).active.where(public: true).ordered }
    scope :ordered, -> { order(:position) }

    def free?
      price_cents.zero?
    end

    def feature?(flag)
      features.include?(flag.to_s)
    end

    # Returns the raw column value. nil means unlimited.
    def limit(attribute)
      public_send(attribute)
    end

    # nil = unlimited → never reached.
    def limit_reached?(attribute, current_count)
      max = read_attribute(attribute)
      return false if max.nil?
      current_count >= max
    end

    def whatsapp_unlimited?
      read_attribute(:whatsapp_monthly_quota).nil?
    end

    def requires_payment_method?(method)
      return true if allowed_payment_methods.blank?
      allowed_payment_methods.include?(method.to_s)
    end

    def self.trial_plan(product: Billing::Product.crm)
      for_product(product).find_by!(trial_default: true)
    end

    def self.find_by_slug!(slug, product: Billing::Product.crm)
      for_product(product).find_by!(slug: slug)
    end
  end
end
