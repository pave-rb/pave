# frozen_string_literal: true

module Pave
  module Tenancy
    class Space < ActiveRecord::Base
      self.table_name = "spaces"

      has_many :space_memberships, class_name: "Pave::Tenancy::SpaceMembership",
                                    foreign_key: :space_id, dependent: :destroy, inverse_of: :space
    end
  end
end
