# frozen_string_literal: true

module Ffccmmx
  class Configuration
    attr_accessor :scope, :json_key_io, :httpx_options

    def initialize
      @scope = ["https://www.googleapis.com/auth/firebase.messaging"]

      # set file path
      @json_key_io = nil

      # Or Environment Variable
      # ENV['GOOGLE_ACCOUNT_TYPE'] = 'service_account'
      # ENV['GOOGLE_CLIENT_ID'] = '000000000000000000000'
      # ENV['GOOGLE_CLIENT_EMAIL'] = 'xxxx@xxxx.iam.gserviceaccount.com'
      # ENV['GOOGLE_PRIVATE_KEY'] = '-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n'
      @httpx_options = nil
    end
  end
end
