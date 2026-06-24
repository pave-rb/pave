# frozen_string_literal: true

require "active_support"
require "active_support/current_attributes"

module Pave
  class Current < ActiveSupport::CurrentAttributes
    attribute :user, :actor, :space, :request_id, :impersonator
  end
end
