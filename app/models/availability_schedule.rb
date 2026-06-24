# frozen_string_literal: true

class AvailabilitySchedule < ApplicationRecord
  belongs_to :schedulable, polymorphic: true
  has_many :availability_windows, dependent: :destroy

  accepts_nested_attributes_for :availability_windows, allow_destroy: true

  after_save :refresh_business_hours_cache
  after_commit :broadcast_booking_slot_updates

  def windows_for_date(date)
    availability_windows
      .where(weekday: date.wday)
      .where.not(opens_at: nil)
      .where.not(closes_at: nil)
      .map { |w| { opens_at: w.opens_at, closes_at: w.closes_at } }
  end

  private

  def refresh_business_hours_cache
    return unless defined?(BusinessHoursCacheService)

    BusinessHoursCacheService.call(schedule: self)
  end

  def broadcast_booking_slot_updates
    return unless defined?(Booking::SlotUpdatesBroadcaster)

    Booking::SlotUpdatesBroadcaster.broadcast_for(schedulable)
  end
end
