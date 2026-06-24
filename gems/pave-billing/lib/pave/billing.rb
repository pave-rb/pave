# frozen_string_literal: true

require "pave/billing/version"
require "pave/billing/engine"
require "pave/billing/provider_adapter"
require "pave/billing/webhook_handler"
require "pave/billing/null_adapter"

module Pave
  module Billing
    EntitlementError = Class.new(Pave::Error)

    class << self
      def allowed?(space:, capability:)
        subscription = Pave::Billing::Subscription.find_by(space_id: space.id)
        return false unless subscription
        return false unless subscription.active_subscription?

        plan = subscription.plan
        return false unless plan

        plan.has_capability?(capability)
      end

      def enforce!(space:, capability:, actor: nil, metadata: {})
        if allowed?(space: space, capability: capability)
          true
        else
          audit_metadata = { space_id: space.id, capability: capability }
          audit_metadata[:actor_id] = actor.id if actor
          audit_metadata.merge!(metadata) if metadata.any?

          Pave::Audit.log!(
            key: "billing.plan.enforced",
            actor: actor,
            target: space,
            metadata: audit_metadata
          )

          raise EntitlementError, "Space #{space.id} does not have capability '#{capability}'"
        end
      end

      def debit_credit!(space:, meter:, amount:, source:, idempotency_key: nil, actor: nil)
        latest = Pave::Billing::CreditTransaction.where(space_id: space.id, meter: meter)
                                                  .order(created_at: :desc)
                                                  .first
        current_balance = latest&.balance_after.to_i
        new_balance = current_balance + amount
        raise Pave::Error, "Insufficient credit for meter '#{meter}'" if new_balance.negative?

        transaction = Pave::Billing::CreditTransaction.create!(
          space: space,
          meter: meter,
          amount: amount,
          balance_after: new_balance,
          source: source,
          idempotency_key: idempotency_key,
          actor_id: actor&.id,
          metadata: {}
        )

        audit_key = amount.positive? ? "billing.credit.granted" : "billing.credit.debited"
        Pave::Audit.log!(
          key: audit_key,
          actor: actor,
          target: space,
          metadata: {
            meter: meter,
            amount: amount,
            balance_after: new_balance,
            source: source,
            idempotency_key: idempotency_key
          }
        )

        transaction
      end

      def grant_credit!(space:, meter:, amount:, source:, idempotency_key: nil, actor: nil)
        raise Pave::Error, "Grant amount must be positive" unless amount.positive?

        debit_credit!(
          space: space,
          meter: meter,
          amount: amount,
          source: source,
          idempotency_key: idempotency_key,
          actor: actor
        )
      end

      def current_balance(space:, meter:)
        latest = Pave::Billing::CreditTransaction.where(space_id: space.id, meter: meter)
                                                  .order(created_at: :desc)
                                                  .first
        latest&.balance_after.to_i
      end
    end
  end
end
