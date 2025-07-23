# frozen_string_literal: true

module Ffccmmx
  class Error < StandardError; end

  class HTTPXError < Error
    attr_reader :response

    def initialize(response)
      @response = response
      super()
    end
  end

  class HTTPXRetryableError < HTTPXError
    RETRYABLE_STATUS_CODES = [408, 429, 500, 502, 503, 504].freeze
    private_constant :RETRYABLE_STATUS_CODES
    def self.retryable_error?(error)
      return false unless error.respond_to?(:response)
      return false if error.response.nil?

      RETRYABLE_STATUS_CODES.include?(error.response.status)
    end

    def retry_time(count: 1)
      retry_seconds = response.headers["retry-after"] ? response.headers["retry-after"].to_i : 2**count
      Time.now + retry_seconds
    end
  end
end
