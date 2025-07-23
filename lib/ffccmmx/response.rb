# frozen_string_literal: true

require "ffccmmx/exceptions"

module Ffccmmx
  class Response
    def initialize(response)
      @response = response
    end

    def value
      @response.raise_for_status
    rescue HTTPX::Error => e
      if Ffccmmx::HTTPXRetryableError.retryable_error?(e)
        raise Ffccmmx::HTTPXRetryableError, response: e.response, cause: e
      end

      raise Ffccmmx::HTTPXError, response: e.response, cause: e
    rescue StandardError => e
      raise Ffccmmx::Error, cause: e
    end
  end
end
