# frozen_string_literal: true

require "rails"

module Pave
  module Tenancy
    class Engine < ::Rails::Engine
      isolate_namespace Pave::Tenancy
    end
  end
end
