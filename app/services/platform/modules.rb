# frozen_string_literal: true

module Platform
  class Modules
    UnknownKey = Class.new(KeyError)

    Definition = Data.define(:key, :entitlement_key, :permission, :navigation)

    def self.all
      registry.values
    end

    def self.find(key)
      registry.fetch(key.to_s) { raise UnknownKey, "Unknown platform module: #{key}" }
    end

    def self.available?(space:, key:)
      new(space: space, user: nil).available?(key)
    end

    def self.authorized?(space:, user:, key:)
      new(space: space, user: user).authorized?(key)
    end

    def self.visible?(space:, user:, key:)
      new(space: space, user: user).visible?(key)
    end

    class << self
      alias_method :show?, :visible?
    end

    def self.navigation_for(space:, user:)
      new(space: space, user: user).navigation
    end

    def self.registry
      # Legacy facade for tenant module visibility; R6 backoffice panels are registered separately.
      Pave.backoffice.modules.to_h do |definition|
        [
          definition.key,
          Definition.new(
            key: definition.key,
            entitlement_key: definition.metadata.fetch(:entitlement_key),
            permission: definition.metadata.fetch(:permission),
            navigation: definition.metadata.fetch(:navigation)
          )
        ]
      end.freeze
    end

    def initialize(space:, user:)
      @space = space
      @user = user
    end

    def available?(key)
      definition = self.class.find(key)
      return false if @space.blank?

      Billing::Entitlements.allowed?(space: @space, key: definition.entitlement_key)
    end

    def authorized?(key)
      definition = self.class.find(key)
      return false if definition.permission.present? && @user.blank?
      return true if definition.permission.blank?

      PermissionService.can?(user: @user, permission: definition.permission, space: @space)
    end

    def visible?(key)
      available?(key) && authorized?(key)
    end

    def navigation
      self.class.all.select { |definition| definition.navigation && visible?(definition.key) }
    end
  end
end
