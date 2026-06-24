# frozen_string_literal: true

require "test_helper"

module Tenancy
  class MembershipsTest < ActiveSupport::TestCase
    test "for_space scopes memberships to the given space" do
      memberships = Tenancy::Memberships.for_space(space: spaces(:one))

      assert_includes memberships.map(&:user), users(:manager)
      assert_includes memberships.map(&:user), users(:secretary)
      assert_not_includes memberships.map(&:user), users(:manager_two)
    end

    test "for_user scopes memberships to the given user" do
      memberships = Tenancy::Memberships.for_user(user: users(:manager_two))

      assert_equal [ spaces(:two) ], memberships.map(&:space)
    end

    test "add_user is idempotent for an existing membership" do
      membership = Tenancy::Memberships.add_user(space: spaces(:one), user: users(:secretary))

      assert_equal space_memberships(:secretary_in_one), membership
      assert_equal 1, SpaceMembership.where(space: spaces(:one), user: users(:secretary)).count
    end

    test "add_user creates a membership for a new user" do
      user = User.create!(
        email: "new-member@example.com",
        password: "password123",
        name: "New Member"
      )
      SpaceMembership.where(user_id: user.id).delete_all

      membership = Tenancy::Memberships.add_user(space: spaces(:one), user:)

      assert_equal spaces(:one), membership.space
      assert_equal user, membership.user
    end

    test "product activation authority is limited to the space owner" do
      assert Tenancy::Memberships.authorized_for_product_activation?(space: spaces(:one), user: users(:manager))
      assert_not Tenancy::Memberships.authorized_for_product_activation?(space: spaces(:one), user: users(:secretary))
      assert_not Tenancy::Memberships.authorized_for_product_activation?(space: spaces(:one), user: users(:manager_two))
    end
  end
end
