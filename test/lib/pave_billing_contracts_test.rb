# frozen_string_literal: true

require "test_helper"

class PaveBillingContractsTest < ActiveSupport::TestCase
  test "runtime billing plan maps to billing_plans table" do
    assert_equal "billing_plans", Pave::Billing::Plan.table_name
  end

  test "runtime billing plan has generic fields" do
    column_names = Pave::Billing::Plan.columns.map(&:name)

    assert_includes column_names, "id"
    assert_includes column_names, "slug"
    assert_includes column_names, "name"
    assert_includes column_names, "active"
    assert_includes column_names, "price_cents"
    assert_includes column_names, "features"
    assert_includes column_names, "position"
    assert_includes column_names, "created_at"
    assert_includes column_names, "updated_at"
  end

  test "runtime billing plan finds existing plans" do
    plan = Pave::Billing::Plan.find_by(slug: "essential")

    assert_not_nil plan
    assert_equal "Essential", plan.name
    assert plan.active?
  end

  test "runtime billing plan active scope" do
    plans = Pave::Billing::Plan.active

    assert plans.any?
    assert plans.all?(&:active)
  end

  test "runtime billing plan detects free plan" do
    plan = Pave::Billing::Plan.find_by(slug: "essential")

    assert_not plan.free?
  end

  test "runtime billing plan checks capabilities" do
    pro = Pave::Billing::Plan.find_by(slug: "pro")

    assert pro.has_capability?("personalized_booking_page")
    assert pro.has_capability?("whatsapp_included_quota")
    assert_not pro.has_capability?("nonexistent_feature")
  end

  test "runtime billing subscription maps to subscriptions table" do
    assert_equal "subscriptions", Pave::Billing::Subscription.table_name
  end

  test "runtime billing subscription has generic fields" do
    column_names = Pave::Billing::Subscription.columns.map(&:name)

    assert_includes column_names, "id"
    assert_includes column_names, "space_id"
    assert_includes column_names, "status"
    assert_includes column_names, "billing_plan_id"
    assert_includes column_names, "current_period_start"
    assert_includes column_names, "current_period_end"
    assert_includes column_names, "trial_ends_at"
    assert_includes column_names, "canceled_at"
    assert_includes column_names, "created_at"
    assert_includes column_names, "updated_at"
  end

  test "runtime billing subscription finds existing subscriptions" do
    sub = Pave::Billing::Subscription.first

    assert_not_nil sub
    assert sub.active_subscription?
  end

  test "runtime billing subscription belongs to plan" do
    sub = Pave::Billing::Subscription.first

    assert_not_nil sub.plan
    assert_kind_of Pave::Billing::Plan, sub.plan
  end

  test "runtime billing subscription exposes generic provider accessors" do
    sub = Pave::Billing::Subscription.first

    assert_respond_to sub, :provider_customer_id
    assert_respond_to sub, :provider_subscription_id
    assert_respond_to sub, :provider_name
  end

  test "runtime billing event maps to billing_events table" do
    assert_equal "billing_events", Pave::Billing::BillingEvent.table_name
  end

  test "runtime billing event is append-only" do
    event = Pave::Billing::BillingEvent.first

    assert_raises(ActiveRecord::ReadOnlyRecord) do
      event.update!(event_type: "plan.changed")
    end
  end

  test "runtime billing event belongs to subscription" do
    event = Pave::Billing::BillingEvent.first

    assert_not_nil event.subscription
    assert_kind_of Pave::Billing::Subscription, event.subscription
  end

  test "runtime billing product maps to billing_products table" do
    assert_equal "billing_products", Pave::Billing::Product.table_name
  end

  test "runtime billing product has plans" do
    product = Pave::Billing::Product.find_by(key: "crm")

    assert product.plans.any?
    assert_kind_of Pave::Billing::Plan, product.plans.first
  end

  test "allowed? returns false for space without subscription" do
    space = spaces(:without_subscription)

    assert_not Pave::Billing.allowed?(space: space, capability: "anything")
  end

  test "allowed? returns true when plan has capability" do
    space = spaces(:two)

    assert Pave::Billing.allowed?(space: space, capability: "personalized_booking_page")
  end

  test "allowed? returns false when plan lacks capability" do
    space = spaces(:two)

    assert_not Pave::Billing.allowed?(space: space, capability: "nonexistent")
  end

  test "enforce! returns true when capability is allowed" do
    result = Pave::Billing.enforce!(
      space: spaces(:two),
      capability: "personalized_booking_page"
    )

    assert result
  end

  test "enforce! raises EntitlementError when capability is missing" do
    assert_raises Pave::Billing::EntitlementError do
      Pave::Billing.enforce!(
        space: spaces(:two),
        capability: "nonexistent_capability"
      )
    end
  end

  test "enforce! writes audit event on denial" do
    assert_difference -> { Pave::Audit::AuditEvent.where(key: "billing.plan.enforced").count }, 1 do
      Pave::Billing.enforce!(
        space: spaces(:two),
        capability: "blocked_feature"
      ) rescue nil
    end
  end

  test "debit_credit! grants credits and updates balance" do
    space = spaces(:one)

    txn = Pave::Billing.debit_credit!(
      space: space,
      meter: "messages",
      amount: 100,
      source: "test_grant",
      idempotency_key: "dc-test-001"
    )

    assert txn.persisted?
    assert_equal 100, txn.balance_after
    assert_equal "messages", txn.meter
    assert txn.credit?
  end

  test "debit_credit! debits credits and updates balance" do
    space = spaces(:one)
    Pave::Billing.debit_credit!(space: space, meter: "messages", amount: 100, source: "grant")

    txn = Pave::Billing.debit_credit!(
      space: space,
      meter: "messages",
      amount: -30,
      source: "usage"
    )

    assert txn.persisted?
    assert_equal 70, txn.balance_after
    assert txn.debit?
  end

  test "debit_credit! raises on insufficient credit" do
    assert_raises Pave::Error do
      Pave::Billing.debit_credit!(
        space: spaces(:one),
        meter: "messages",
        amount: -1,
        source: "usage"
      )
    end
  end

  test "debit_credit! writes audit events" do
    space = spaces(:one)

    assert_difference -> { Pave::Audit::AuditEvent.where(key: "billing.credit.granted").count }, 1 do
      Pave::Billing.debit_credit!(
        space: space,
        meter: "messages",
        amount: 50,
        source: "test",
        idempotency_key: "dc-audit-test-001"
      )
    end
  end

  test "grant_credit! is a convenience for positive debit_credit!" do
    space = spaces(:one)

    txn = Pave::Billing.grant_credit!(
      space: space,
      meter: "storage",
      amount: 1000,
      source: "purchase"
    )

    assert txn.persisted?
    assert_equal 1000, Pave::Billing.current_balance(space: space, meter: "storage")
  end

  test "grant_credit! raises on non-positive amount" do
    assert_raises Pave::Error do
      Pave::Billing.grant_credit!(
        space: spaces(:one),
        meter: "storage",
        amount: -100,
        source: "invalid"
      )
    end
  end

  test "current_balance returns zero for empty meter" do
    assert_equal 0, Pave::Billing.current_balance(space: spaces(:one), meter: "nonexistent_meter")
  end

  test "current_balance reflects latest transaction" do
    space = spaces(:one)
    Pave::Billing.debit_credit!(space: space, meter: "api_calls", amount: 500, source: "grant")
    Pave::Billing.debit_credit!(space: space, meter: "api_calls", amount: -100, source: "usage")

    assert_equal 400, Pave::Billing.current_balance(space: space, meter: "api_calls")
  end

  test "ProviderAdapter defines abstract contract" do
    adapter = Pave::Billing::ProviderAdapter.new

    assert_raises NotImplementedError do
      adapter.create_customer(space: nil)
    end

    assert_raises NotImplementedError do
      adapter.create_subscription(space: nil, plan: nil, customer_id: nil)
    end

    assert_raises NotImplementedError do
      adapter.cancel_subscription(nil)
    end

    assert_raises NotImplementedError do
      adapter.process_webhook(payload: {}, headers: {})
    end
  end

  test "NullAdapter returns fake responses" do
    adapter = Pave::Billing::NullAdapter.new
    space = spaces(:one)

    assert_equal "null", adapter.name
    assert_equal "null_customer_#{space.id}", adapter.create_customer(space: space)
    assert adapter.cancel_subscription("test_sub_id")
  end

  test "WebhookHandler defines abstract contract" do
    handler = Pave::Billing::WebhookHandler.new

    assert_raises NotImplementedError do
      handler.handle(payload: {}, headers: {})
    end

    assert_raises NotImplementedError do
      handler.normalize(payload: {}, headers: {})
    end
  end

  test "CreditTransaction maps to billing_credit_transactions table" do
    assert_equal "billing_credit_transactions", Pave::Billing::CreditTransaction.table_name
  end

  test "credit? and debit? helpers" do
    space = spaces(:one)
    credit = Pave::Billing::CreditTransaction.create!(
      space: space, meter: "test", amount: 10, balance_after: 10, source: "test"
    )
    debit = Pave::Billing::CreditTransaction.create!(
      space: space, meter: "test", amount: -5, balance_after: 5, source: "test"
    )

    assert credit.credit?
    assert_not credit.debit?
    assert debit.debit?
    assert_not debit.credit?
  end

  test "idempotency_key is unique at database level" do
    space = spaces(:one)
    Pave::Billing::CreditTransaction.create!(
      space: space, meter: "test", amount: 10, balance_after: 10,
      source: "test", idempotency_key: "unique-key-001"
    )

    assert_raises ActiveRecord::RecordNotUnique do
      txn = Pave::Billing::CreditTransaction.new(
        space: space, meter: "test", amount: 20, balance_after: 30,
        source: "test", idempotency_key: "unique-key-001"
      )
      txn.save(validate: false)
    end
  end

  test "no provider-specific leakage in runtime billing" do
    runtime_files = Dir.glob("gems/pave-billing/app/**/*.rb") +
                    Dir.glob("gems/pave-billing/lib/**/*.rb")

    forbidden_patterns = [
      /[Aa]saas/, /[Aa]nella/, /[Ww]hatsapp/i, /[Aa]ppointment/, /[Cc]RM/
    ]

    violations = runtime_files.select do |f|
      content = File.read(f)
      forbidden_patterns.any? { |pat| content.match?(pat) }
    end

    assert_empty violations,
                 "Forbidden references found in runtime billing: #{violations.join(', ')}"
  end

  test "runtime billing does not reference legacy Billing::* constants" do
    runtime_files = Dir.glob("gems/pave-billing/app/**/*.rb") +
                    Dir.glob("gems/pave-billing/lib/**/*.rb")

    legacy_refs = runtime_files.select do |f|
      content = File.read(f)
      # Allow self-references to Pave::Billing::*
      content.match?(/[^_]Billing::(?!Billing)/) && !content.include?("Pave::Billing")
    end

    assert_empty legacy_refs,
                 "Legacy Billing:: references in runtime: #{legacy_refs.join(', ')}"
  end
end
