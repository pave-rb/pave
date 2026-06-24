# frozen_string_literal: true

require "test_helper"

module Billing
  class SubscriptionTest < ActiveSupport::TestCase
    def valid_attrs
      {
        space:         fresh_space,
        billing_product: billing_products(:crm),
        billing_plan:  billing_plans(:essential),
        status:        :trialing,
        trial_ends_at: 14.days.from_now
      }
    end

    def fresh_space
      @fresh_space ||= Space.create!(name: "Subscription Test Space #{SecureRandom.hex(4)}", timezone: "UTC")
    end

    test "valid subscription can be created" do
      sub = Billing::Subscription.new(valid_attrs)
      assert sub.valid?
    end

    test "billing_plan is required" do
      sub = Billing::Subscription.new(valid_attrs.merge(billing_plan: nil))
      assert_not sub.valid?
      assert sub.errors[:billing_plan].any?
    end

    test "billing_product is required when it cannot be inferred from a plan" do
      sub = Billing::Subscription.new(valid_attrs.except(:billing_product, :billing_plan))
      assert_not sub.valid?
      assert sub.errors[:billing_product].any?
    end

    test "billing plan must belong to subscription billing product" do
      sub = Billing::Subscription.new(valid_attrs.merge(billing_product: billing_products(:peti_vet)))

      assert_not sub.valid?
      assert sub.errors[:billing_plan].any?
    end

    test "pending billing plan must belong to subscription billing product" do
      peti_plan = Billing::Plan.create!(
        billing_product: billing_products(:peti_vet),
        slug: "peti_pending",
        name: "Peti Pending",
        price_cents: 7990,
        position: 1
      )
      sub = Billing::Subscription.new(valid_attrs.merge(pending_billing_plan: peti_plan))

      assert_not sub.valid?
      assert sub.errors[:pending_billing_plan].any?
    end

    test "allows one active subscription per space per billing product" do
      peti_plan = Billing::Plan.create!(
        billing_product: billing_products(:peti_vet),
        slug: "peti_active",
        name: "Peti Active",
        price_cents: 7990,
        position: 1
      )
      sub = Billing::Subscription.new(
        space: spaces(:one),
        billing_product: billing_products(:peti_vet),
        billing_plan: peti_plan,
        status: :active
      )

      assert sub.valid?
    end

    test "rejects duplicate non-expired subscription for same space and product" do
      sub = Billing::Subscription.new(valid_attrs.merge(space: spaces(:one), status: :active))

      assert_not sub.valid?
      assert sub.errors[:space_id].any?
    end

    test "status enum resolves trialing" do
      sub = Billing::Subscription.new(valid_attrs.merge(status: :trialing))
      assert sub.trialing?
    end

    test "status enum resolves active" do
      sub = Billing::Subscription.new(valid_attrs.merge(status: :active))
      assert sub.active?
    end

    test "#plan returns the Billing::Plan object" do
      sub = subscriptions(:one)
      assert_instance_of Billing::Plan, sub.plan
      assert_equal "essential", sub.plan.slug
    end

    test "#plan returns pro plan for pro subscription" do
      sub = subscriptions(:two)
      assert_equal "pro", sub.plan.slug
    end

    test "platform demo subscriptions cannot keep Asaas billing wiring" do
      sub = Billing::Subscription.new(
        valid_attrs.merge(
          funding_source: :platform_demo,
          status: :active,
          asaas_customer_id: "cus_demo",
          asaas_subscription_id: "sub_demo"
        )
      )

      assert_not sub.valid?
      assert sub.errors[:base].any?
    end

    test "platform demo subscriptions are not customer billable" do
      sub = Billing::Subscription.new(valid_attrs.merge(funding_source: :platform_demo, status: :active))

      assert sub.platform_demo?
      assert_not sub.customer_billable?
    end

    test "customer paid subscriptions with Asaas customer are customer billable" do
      sub = subscriptions(:two)
      sub.update!(asaas_customer_id: "cus_billable")

      assert sub.customer_paid?
      assert sub.customer_billable?
    end
  end
end
