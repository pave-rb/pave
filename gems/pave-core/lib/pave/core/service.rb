# frozen_string_literal: true

module Pave
  class Service
    def self.call(...)
      new.call(...)
    end

    private

    def success(value = nil, **context)
      Result.success(value, **context)
    end

    def failure(error, **context)
      Result.failure(error, **context)
    end
  end
end
