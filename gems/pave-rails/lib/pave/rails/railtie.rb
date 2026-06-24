# frozen_string_literal: true

require "rails"

module Pave
  module Rails
    class Railtie < ::Rails::Railtie
      # TODO(planned): Hook into Rails boot sequence, configure pave-core,
      # wire product/plugin loading, set up generators.
    end
  end
end
