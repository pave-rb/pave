# frozen_string_literal: true

class AppChromeBroadcaster
  def self.broadcast_for(space:)
    new(space).broadcast
  end

  def initialize(space)
    @space = space
  end

  def broadcast
    return if space.blank?

    broadcast_inbox_unread_badge
    broadcast_pending_appointments_badge
  end

  private

  attr_reader :space

  def broadcast_inbox_unread_badge
    Turbo::StreamsChannel.broadcast_replace_to(
      stream_name,
      target: "dock_inbox_unread_badge",
      partial: "shared/inbox_unread_badge",
      locals: { space: space, target_id: "dock_inbox_unread_badge" }
    )
  end

  def broadcast_pending_appointments_badge
    Turbo::StreamsChannel.broadcast_replace_to(
      stream_name,
      target: "dock_pending_appointments_badge",
      partial: "shared/pending_badge",
      locals: { count: space.appointments.pending.count, target_id: "dock_pending_appointments_badge" }
    )
  end

  def stream_name
    [ space, :app ]
  end
end
