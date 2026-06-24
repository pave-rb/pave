require "test_helper"

module DemoScheduling
  class BookAppointmentTest < ActiveSupport::TestCase
    test "creates appointment on success" do
      result = DemoScheduling::BookAppointment.call(
        space: nil,
        title: "New Appointment",
        scheduled_at: Time.current
      )

      assert_predicate result, :success?
      assert_kind_of DemoScheduling::Appointment, result.value
      assert_equal "New Appointment", result.value.title
    end

    test "fails with validation error" do
      result = DemoScheduling::BookAppointment.call(
        space: nil,
        title: "",
        scheduled_at: nil
      )

      assert_predicate result, :failure?
    end
  end
end
