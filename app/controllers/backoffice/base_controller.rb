# frozen_string_literal: true

module Backoffice
  # Compatibility shim for legacy product/runtime controllers.
  # Delete after controllers inherit from Pave::Backoffice::BaseController.
  class BaseController < Pave::Backoffice::BaseController
  end
end
