require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  # ---------------------------------------------------------------------------
  # Validations
  # ---------------------------------------------------------------------------

  test "valid with all required attributes" do
    n = Notification.new(
      user:          users(:manager),
      notifiable:    appointments(:one),
      event_type:    "appointment_booked",
      title:         "New appointment",
      body:          "Someone booked"
    )
    assert n.valid?
  end

  test "invalid without title" do
    n = notifications(:booking_received)
    n.title = nil
    assert_not n.valid?
    assert n.errors[:title].any?
  end

  test "invalid without body" do
    n = notifications(:booking_received)
    n.body = nil
    assert_not n.valid?
    assert n.errors[:body].any?
  end

  test "invalid without event_type" do
    n = notifications(:booking_received)
    n.event_type = nil
    assert_not n.valid?
    assert n.errors[:event_type].any?
  end

  test "invalid without user" do
    n = notifications(:booking_received)
    n.user = nil
    assert_not n.valid?
  end

  test "invalid without notifiable" do
    n = notifications(:booking_received)
    n.notifiable = nil
    assert_not n.valid?
  end

  # ---------------------------------------------------------------------------
  # Scopes
  # ---------------------------------------------------------------------------

  test "ordered returns newest first" do
    notifications(:booking_received).update_column(:created_at, 1.hour.ago)
    notifications(:older_booking).update_column(:created_at, 2.hours.ago)
    ordered = Notification.ordered.to_a
    assert ordered.first.created_at >= ordered.last.created_at
  end

  test "recent defaults to 10" do
    user = users(:manager)
    11.times do |i|
      Notification.create!(
        user: user, notifiable: appointments(:one),
        event_type: "appointment_booked",
        title: "T#{i}", body: "B#{i}"
      )
    end
    assert_equal 10, Notification.recent.count
  end

  test "recent accepts custom limit" do
    assert_equal 2, Notification.recent(2).count
  end

  # ---------------------------------------------------------------------------
  # target_path
  # ---------------------------------------------------------------------------

  test "target_path for Appointment" do
    n = notifications(:booking_received)
    assert_equal n.notifiable_type, "Appointment"
    result = n.target_path
    assert_equal "spaces/appointments", result[:controller]
    assert_equal "show",               result[:action]
    assert_equal n.notifiable_id,      result[:id]
  end

  test "target_path for Billing::Subscription" do
    n = notifications(:booking_received)
    n.notifiable = subscriptions(:one)
    result = n.target_path
    assert_equal "spaces/billing", result[:controller]
    assert_equal "show",           result[:action]
    assert_nil result[:id]
  end

  test "target_path for Billing::MessageCredit" do
    n = notifications(:booking_received)
    n.notifiable = message_credits(:one)
    result = n.target_path
    assert_equal "spaces/credits", result[:controller]
    assert_equal "show",           result[:action]
  end

  test "target_path returns nil for unknown notifiable type" do
    n = notifications(:booking_received)
    n.notifiable_type = "SomeUnknownModel"
    assert_nil n.target_path
  end

  test "creation enqueues push delivery" do
    assert_enqueued_with(job: Notifications::DeliverPushNotificationJob) do
      Notification.create!(
        user: users(:manager),
        notifiable: appointments(:one),
        event_type: "appointment_booked",
        title: "New appointment",
        body: "Someone booked"
      )
    end
  end
end
