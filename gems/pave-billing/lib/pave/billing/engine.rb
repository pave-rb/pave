# frozen_string_literal: true

require "rails"

module Pave
  module Billing
    class Engine < ::Rails::Engine
      isolate_namespace Pave::Billing
    end
  end
end
