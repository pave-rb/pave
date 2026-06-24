# frozen_string_literal: true

class RegistrationSetting < ApplicationRecord
  SINGLETON_GUARD = 0

  validates :enabled, inclusion: { in: [ true, false ] }
  validates :singleton_guard, numericality: { equal_to: SINGLETON_GUARD }, uniqueness: true

  def self.current
    order(:id).first_or_create!(singleton_guard: SINGLETON_GUARD)
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def self.enabled?
    current.enabled?
  end
end
