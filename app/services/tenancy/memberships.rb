# frozen_string_literal: true

module Tenancy
  class Memberships
    def self.for_space(space:)
      SpaceMembership.where(space_id: space.id)
    end

    def self.for_user(user:)
      SpaceMembership.where(user_id: user.id)
    end

    def self.add_user(space:, user:, role: nil)
      membership = SpaceMembership.find_or_initialize_by(space_id: space.id, user_id: user.id)
      membership.role = role if role.present? && membership.respond_to?(:role=)
      membership.save! if membership.new_record? || membership.changed?
      membership
    end

    def self.authorized_for_product_activation?(space:, user:)
      Tenancy::Spaces.owner?(space:, user:)
    end
  end
end
