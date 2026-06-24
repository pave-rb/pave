# frozen_string_literal: true

module Notifications
  class DeliverPushNotificationJob < ApplicationJob
    queue_as :default

    discard_on ActiveRecord::RecordNotFound, report: true

    def perform(notification_id)
      notification = Notification.includes(user: :push_subscriptions).find(notification_id)

      Notifications::PushDelivery.call(notification: notification)
    end
  end
end
