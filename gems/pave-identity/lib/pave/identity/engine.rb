# frozen_string_literal: true

require "rails"

module Pave
  module Identity
    class Engine < ::Rails::Engine
      isolate_namespace Pave::Identity
    end
  end
end
