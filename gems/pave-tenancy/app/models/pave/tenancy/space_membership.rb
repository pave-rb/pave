# frozen_string_literal: true

module Pave
  module Tenancy
    class SpaceMembership < ActiveRecord::Base
      self.table_name = "space_memberships"

      belongs_to :space, class_name: "Pave::Tenancy::Space"

      validates :user_id, uniqueness: { scope: :space_id }
    end
  end
end
