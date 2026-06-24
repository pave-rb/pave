# frozen_string_literal: true

module Pave
  # Compatibility shim for callers that still reference the pre-R6 registry name.
  # Delete after all callers use Pave::Backoffice::Registry directly.
  class BackofficeRegistry < Pave::Backoffice::Registry
  end
end
