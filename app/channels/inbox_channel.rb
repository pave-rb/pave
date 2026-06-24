# frozen_string_literal: true

class InboxChannel < ApplicationCable::Channel
  def subscribed
    return reject unless current_space

    stream_for [ current_space, :inbox ]
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
