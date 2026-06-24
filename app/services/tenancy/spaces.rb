# frozen_string_literal: true

module Tenancy
  class Spaces
    def self.find_reference(space_id:)
      Space.find(space_id)
    end

    def self.create_with_owner(owner:, attributes: {})
      CreateOwnerSpace::Implementation.call(owner, attributes:)
    end

    def self.visible_to(user:)
      Space.joins(:space_memberships)
           .where(space_memberships: { user_id: user.id })
           .distinct
    end

    def self.owner?(space:, user:)
      space.present? && user.present? && space.owner_id == user.id
    end
  end
end
