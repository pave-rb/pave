require "test_helper"

module DemoScheduling
  class AppointmentTest < ActiveSupport::TestCase
    test "valid appointment can be created" do
      appointment = DemoScheduling::Appointment.new(
        title: "Test Appointment",
        scheduled_at: Time.current
      )
      assert appointment.valid?
    end

    test "invalid without title" do
      appointment = DemoScheduling::Appointment.new(scheduled_at: Time.current)
      assert_not appointment.valid?
      assert_includes appointment.errors[:title], "can't be blank"
    end

    test "invalid without scheduled_at" do
      appointment = DemoScheduling::Appointment.new(title: "Test")
      assert_not appointment.valid?
      assert_includes appointment.errors[:scheduled_at], "can't be blank"
    end
  end
end
