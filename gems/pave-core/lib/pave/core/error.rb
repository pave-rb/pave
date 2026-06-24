# frozen_string_literal: true

module Pave
  class Error < StandardError
    attr_reader :code, :context

    class << self
      def default_code(value = nil)
        @default_code = value.to_sym if value
        @default_code ||= underscored_name.to_sym
      end

      private

      def underscored_name
        name.split("::").last.gsub(/([a-z\d])([A-Z])/, "\\1_\\2").downcase
      end
    end

    def initialize(message = nil, code: self.class.default_code, context: {})
      @code = code.to_sym
      @context = context.freeze
      super(message || @code.to_s)
    end
  end

  class ConfigurationError < Error
    default_code :configuration_error
  end

  class RegistryError < Error
    default_code :registry_error
  end

  class ValidationError < Error
    default_code :validation_error
  end

  class AuthorizationError < Error
    default_code :authorization_error
  end

  class NotFoundError < Error
    default_code :not_found_error
  end

  class ConflictError < Error
    default_code :conflict_error
  end

  class DependencyError < Error
    default_code :dependency_error
  end

  class TenantScopeError < Error
    default_code :tenant_scope_error
  end

  class IntegrationError < Error
    default_code :integration_error
  end
end
