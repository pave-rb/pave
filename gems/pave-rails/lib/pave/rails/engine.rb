# frozen_string_literal: true

require "rails"

module Pave
  module Rails
    class Engine < ::Rails::Engine
      isolate_namespace Pave::Rails

      # TODO(planned): Add install generator, upgrade tasks, product boot wiring.
    end
  end
end
