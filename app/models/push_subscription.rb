# frozen_string_literal: true

class PushSubscription < ApplicationRecord
  belongs_to :user

  encrypts :endpoint
  encrypts :p256dh
  encrypts :auth

  before_validation :set_endpoint_sha256

  validates :endpoint, presence: true
  validates :endpoint_sha256, presence: true, uniqueness: true
  validates :p256dh, presence: true
  validates :auth, presence: true

  scope :active, -> { where(active: true) }

  def self.endpoint_digest(endpoint)
    return if endpoint.blank?

    OpenSSL::Digest::SHA256.hexdigest(endpoint.to_s)
  end

  def record_success!
    update!(
      active: true,
      failure_count: 0,
      last_error: nil,
      last_success_at: Time.current
    )
  end

  def record_failure!(message)
    update!(
      failure_count: failure_count + 1,
      last_error: message.to_s,
      last_failure_at: Time.current
    )
  end

  def deactivate!(message = nil)
    update!(
      active: false,
      last_error: message.presence || last_error,
      last_failure_at: Time.current
    )
  end

  private

  def set_endpoint_sha256
    self.endpoint_sha256 = self.class.endpoint_digest(endpoint)
  end
end
