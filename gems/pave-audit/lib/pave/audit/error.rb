# frozen_string_literal: true

module Pave
  module Audit
    class Error < Pave::Error
      default_code :audit_error
    end
  end
end
