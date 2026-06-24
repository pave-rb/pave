# frozen_string_literal: true

require "test_helper"

class PaveIdentityContractsTest < ActiveSupport::TestCase
  test "runtime identity user maps to users table" do
    assert_equal "users", Pave::Identity::User.table_name
  end

  test "runtime identity user has generic identity fields" do
    column_names = Pave::Identity::User.columns.map(&:name)

    assert_includes column_names, "id"
    assert_includes column_names, "email"
    assert_includes column_names, "name"
    assert_includes column_names, "system_role"
    assert_includes column_names, "created_at"
    assert_includes column_names, "updated_at"
  end

  test "runtime identity user finds existing users" do
    admin = Pave::Identity::User.find_by(email: "admin@example.com")

    assert_not_nil admin
    assert_equal "Platform Admin", admin.name
    assert admin.admin?
  end

  test "runtime identity user admins scope" do
    admins = Pave::Identity::User.admins

    assert admins.any?
    assert admins.all?(&:admin?)
  end

  test "current_user returns nil outside request context" do
    assert_nil Pave::Identity.current_user
  end

  test "current_actor falls back to current_user" do
    Pave::Current.reset
    assert_nil Pave::Identity.current_actor
  end

  test "current_actor returns actor when set" do
    user = users(:manager)
    Pave::Current.actor = user

    assert_equal user, Pave::Identity.current_actor
    assert_equal user, Pave::Identity.current_actor
  ensure
    Pave::Current.reset
  end

  test "current_user reflects Pave::Current.user" do
    user = users(:manager)
    Pave::Current.user = user

    assert_equal user, Pave::Identity.current_user
  ensure
    Pave::Current.reset
  end

  test "current_impersonator returns impersonator when set" do
    admin = users(:admin)
    Pave::Current.impersonator = admin

    assert_equal admin, Pave::Identity.current_impersonator
  ensure
    Pave::Current.reset
  end

  test "current_actor prioritizes actor over user" do
    actor_user = users(:admin)
    regular_user = users(:manager)
    Pave::Current.actor = actor_user
    Pave::Current.user = regular_user

    assert_equal actor_user, Pave::Identity.current_actor
  ensure
    Pave::Current.reset
  end
end
