# frozen_string_literal: true

require "test_helper"

module Tenancy
  class SpacesTest < ActiveSupport::TestCase
    test "find_reference returns a space by stable id" do
      assert_equal spaces(:one), Tenancy::Spaces.find_reference(space_id: spaces(:one).id)
    end

    test "find_reference raises when the space does not exist" do
      assert_raises(ActiveRecord::RecordNotFound) do
        Tenancy::Spaces.find_reference(space_id: Space.maximum(:id).to_i + 1)
      end
    end

    test "visible_to returns only spaces the user belongs to" do
      visible_spaces = Tenancy::Spaces.visible_to(user: users(:manager))

      assert_includes visible_spaces, spaces(:one)
      assert_not_includes visible_spaces, spaces(:two)
    end

    test "owner checks the explicit space owner reference" do
      assert Tenancy::Spaces.owner?(space: spaces(:one), user: users(:manager))
      assert_not Tenancy::Spaces.owner?(space: spaces(:one), user: users(:secretary))
    end

    test "create_with_owner creates through the tenancy namespace" do
      user = User.create!(
        email: "tenant-owner@example.com",
        password: "password123",
        name: "Tenant Owner"
      )
      SpaceMembership.where(user_id: user.id).delete_all
      Space.where(owner_id: user.id).destroy_all

      space = Tenancy::Spaces.create_with_owner(owner: user, attributes: { name: "Tenant Co." })

      assert_equal "Tenant Co.", space.name
      assert_equal user, space.owner
      assert_equal space, user.reload.space
      assert Tenancy::Spaces.owner?(space:, user:)
    end
  end
end
