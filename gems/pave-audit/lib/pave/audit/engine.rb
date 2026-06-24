# frozen_string_literal: true

require "rails"

module Pave
  module Audit
    class Engine < ::Rails::Engine
      isolate_namespace Pave::Audit
    end
  end
end
