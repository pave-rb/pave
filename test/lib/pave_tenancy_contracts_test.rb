# frozen_string_literal: true

require "test_helper"

class PaveTenancyContractsTest < ActiveSupport::TestCase
  test "current_space returns nil outside with_space block" do
    assert_nil Pave::Tenancy.current_space
  end

  test "with_space sets and resets current_space" do
    space = Pave::Tenancy::Space.new(id: 1, name: "Test Space")

    Pave::Tenancy.with_space(space) do
      assert_same space, Pave::Tenancy.current_space
    end

    assert_nil Pave::Tenancy.current_space
  end

  test "with_space resets to previous value on error" do
    previous = Pave::Tenancy::Space.new(id: 2, name: "Previous")
    Pave::Tenancy.with_space(previous) do
      assert_raises(RuntimeError) do
        Pave::Tenancy.with_space(Pave::Tenancy::Space.new(id: 3)) do
          raise "boom"
        end
      end
      assert_same previous, Pave::Tenancy.current_space
    end
  end

  test "with_space nests correctly" do
    outer = Pave::Tenancy::Space.new(id: 10, name: "Outer")
    inner = Pave::Tenancy::Space.new(id: 20, name: "Inner")

    Pave::Tenancy.with_space(outer) do
      assert_equal 10, Pave::Tenancy.current_space.id

      Pave::Tenancy.with_space(inner) do
        assert_equal 20, Pave::Tenancy.current_space.id
      end

      assert_equal 10, Pave::Tenancy.current_space.id
    end
  end

  test "space_required! raises when no current space" do
    Pave::Current.reset

    error = assert_raises(Pave::Error) { Pave::Tenancy.space_required! }
    assert_equal "No current space set", error.message
  end

  test "space_required! passes when current space is set" do
    Pave::Tenancy.with_space(Pave::Tenancy::Space.new(id: 1)) do
      assert_nothing_raised { Pave::Tenancy.space_required! }
    end
  end

  test "assert_same_space! passes for matching space" do
    space = Pave::Tenancy::Space.create!(name: "Match")
    record = OpenStruct.new(space_id: space.id)

    assert_nothing_raised { Pave::Tenancy.assert_same_space!(record, space) }
  end

  test "assert_same_space! raises for mismatched space" do
    space_a = Pave::Tenancy::Space.create!(name: "A")
    space_b = Pave::Tenancy::Space.create!(name: "B")
    record = OpenStruct.new(space_id: space_a.id)

    error = assert_raises(Pave::Error) { Pave::Tenancy.assert_same_space!(record, space_b) }
    assert_equal "Record does not belong to the current space", error.message
  end

  test "assert_same_space! raises when record has no space_id" do
    space = Pave::Tenancy::Space.create!(name: "NoRef")
    record = OpenStruct.new

    assert_raises(Pave::Error) { Pave::Tenancy.assert_same_space!(record, space) }
  end

  test "runtime space maps to spaces table" do
    assert_equal "spaces", Pave::Tenancy::Space.table_name
  end

  test "runtime space membership maps to space_memberships table" do
    assert_equal "space_memberships", Pave::Tenancy::SpaceMembership.table_name
  end

  test "runtime space has generic fields only" do
    column_names = Pave::Tenancy::Space.columns.map(&:name)

    assert_includes column_names, "id"
    assert_includes column_names, "name"
    assert_includes column_names, "timezone"
    assert_includes column_names, "owner_id"
  end

  test "runtime controller is an ActionController::Base subclass" do
    assert Pave::Tenancy::BaseController < ActionController::Base
  end
end
