# frozen_string_literal: true

module Pave
  module Identity
    module Impersonation
      AUTHORIZED_ROLES = %w[super_admin].freeze

      module_function

      def start!(actor:, target_user:, reason: nil, idempotency_key: nil)
        raise Pave::AuthorizationError, "Not authorized to impersonate" unless authorized?(actor)

        metadata = { reason: reason, target_email: target_user.email, target_name: target_user.name }
        metadata[:idempotency_key] = idempotency_key if idempotency_key

        Pave::Audit.log!(
          key: "identity.impersonation.started",
          actor: actor,
          target: target_user,
          metadata: metadata,
          idempotency_key: idempotency_key
        )

        true
      end

      def stop!(actor:, target_user: nil, idempotency_key: nil)
        metadata = {}
        if target_user
          metadata[:target_email] = target_user.email
          metadata[:target_name] = target_user.name
        end
        metadata[:idempotency_key] = idempotency_key if idempotency_key

        Pave::Audit.log!(
          key: "identity.impersonation.stopped",
          actor: actor,
          target: target_user,
          metadata: metadata,
          idempotency_key: idempotency_key
        )

        true
      end

      def denied!(actor:, target_user:, reason:, idempotency_key: nil)
        metadata = {
          reason: reason,
          target_email: target_user.email,
          target_name: target_user.name
        }
        metadata[:idempotency_key] = idempotency_key if idempotency_key

        Pave::Audit.log!(
          key: "identity.impersonation.denied",
          actor: actor,
          target: target_user,
          metadata: metadata,
          idempotency_key: idempotency_key
        )

        true
      end

      def authorized?(actor)
        return false unless actor.respond_to?(:system_role)

        role = actor.system_role
        role == 0 || role == "super_admin"
      end
    end
  end
end
