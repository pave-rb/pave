# frozen_string_literal: true

module Pave
  module Identity
    class User < ActiveRecord::Base
      self.table_name = "users"

      has_one :space_membership,
              class_name: "Pave::Tenancy::SpaceMembership",
              foreign_key: :user_id,
              dependent: :destroy

      scope :admins, -> { where(system_role: 0) }

      def admin?
        system_role == 0 || system_role == "super_admin"
      end
    end
  end
end
