# frozen_string_literal: true

module Pave
  class Result
    attr_reader :value, :error, :context

    def self.success(value = nil, **context)
      new(success: true, value: value, context: context)
    end

    def self.failure(error, **context)
      new(success: false, error: error, context: context)
    end

    def initialize(success:, value: nil, error: nil, context: {})
      raise ArgumentError, "successful results cannot include an error" if success && error
      raise ArgumentError, "failed results require an error" if !success && error.nil?

      @success = success
      @value = value
      @error = error
      @context = context.freeze
    end

    def success?
      @success
    end

    def failure?
      !success?
    end
  end
end
