# frozen_string_literal: true

require "rails"

module Pave
  module Core
    class Engine < ::Rails::Engine
      isolate_namespace Pave::Core
    end
  end
end
