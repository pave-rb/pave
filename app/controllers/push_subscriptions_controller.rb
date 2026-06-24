# frozen_string_literal: true

class PushSubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def create
    attrs = subscription_attributes
    digest = PushSubscription.endpoint_digest(attrs[:endpoint])
    subscription = digest.present? ? PushSubscription.find_or_initialize_by(endpoint_sha256: digest) : current_user.push_subscriptions.build
    created = subscription.new_record?

    subscription.assign_attributes(attrs)
    subscription.user = current_user
    subscription.active = true
    subscription.failure_count = 0
    subscription.last_error = nil
    subscription.user_agent = request.user_agent

    if subscription.save
      current_user_preference.enable_push_notifications!(permission: "granted")
      render json: { active: subscription.active? }, status: created ? :created : :ok
    else
      render json: { errors: subscription.errors.to_hash }, status: :unprocessable_entity
    end
  end

  def destroy
    endpoint = params[:endpoint].presence || params.dig(:subscription, :endpoint)
    digest = PushSubscription.endpoint_digest(endpoint)

    if digest.present?
      current_user
        .push_subscriptions
        .find_by(endpoint_sha256: digest)
        &.deactivate!("browser unsubscribed")
    end

    current_user_preference.disable_push_notifications!(permission: params[:permission])

    head :no_content
  end

  private

  def current_user_preference
    current_user.user_preference || current_user.create_user_preference!(locale: I18n.default_locale.to_s)
  end

  def subscription_attributes
    raw = params[:subscription]
    permitted = raw.respond_to?(:permit) ? raw.permit(:endpoint, keys: [ :p256dh, :auth ]) : {}
    keys = permitted[:keys] || {}

    {
      endpoint: permitted[:endpoint],
      p256dh: keys[:p256dh],
      auth: keys[:auth]
    }
  end
end
