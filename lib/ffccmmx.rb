# frozen_string_literal: true

require_relative "ffccmmx/version"
require_relative "ffccmmx/client"
require_relative "ffccmmx/configuration"

module Ffccmmx
  BASE_URL = "https://fcm.googleapis.com"
  TOPIC_BASE_URL = "https://iid.googleapis.com"
  private_constant :BASE_URL, :TOPIC_BASE_URL

  class << self
    attr_writer :configuration

    def build(project_id, base_url: BASE_URL, topic_base_url: TOPIC_BASE_URL)
      ::Ffccmmx::Client.new(base_url, topic_base_url, project_id, configuration)
    end
    alias new build

    def configuration
      reset_configuration unless @configuration

      @configuration
    end

    def reset_configuration
      @configuration = ::Ffccmmx::Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
