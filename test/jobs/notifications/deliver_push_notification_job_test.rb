# frozen_string_literal: true

require "test_helper"

module Notifications
  class DeliverPushNotificationJobTest < ActiveJob::TestCase
    test "delivers push notification for persisted notification" do
      notification = notifications(:booking_received)
      delivered_id = nil

      PushDelivery.stub(:call, ->(notification:) { delivered_id = notification.id }) do
        DeliverPushNotificationJob.perform_now(notification.id)
      end

      assert_equal notification.id, delivered_id
    end

    test "discards when notification has been deleted" do
      assert_nothing_raised do
        DeliverPushNotificationJob.perform_now(-1)
      end
    end
  end
end
