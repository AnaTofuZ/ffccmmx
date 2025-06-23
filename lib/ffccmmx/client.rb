# frozen_string_literal: true

require "uri"
require "googleauth"
require "httpx"
require "ffccmmx/exceptions"

module Ffccmmx
  class Client
    V1_ENDPOINT_PREFIX = "/v1/projects/"
    V1_ENDPOINT_SUFFIX = "/messages:send"
    TOPIC_ENDPOINT_PREFIX = "/iid/v1"
    TOPIC_BATCH_SUBSCRIBE_SUFFIX = ":batchAdd"
    TOPIC_BATCH_UNSUBSCRIBE_SUFFIX = ":batchRemove"
    private_constant :V1_ENDPOINT_PREFIX, :V1_ENDPOINT_SUFFIX, :TOPIC_ENDPOINT_PREFIX,
                     :TOPIC_BATCH_SUBSCRIBE_SUFFIX, :TOPIC_BATCH_UNSUBSCRIBE_SUFFIX

    attr_reader :base_url, :topic_base_url, :push_uri, :configuration, :access_token, :access_token_expiry, :httpx

    # rubocop:disable Metrics/MethodLength
    def initialize(base_url, topic_base_url, project_id, configuration) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      @base_url = base_url
      @topic_base_url = topic_base_url
      @project_id = project_id

      @push_uri = URI.join(base_url, V1_ENDPOINT_PREFIX + project_id.to_s + V1_ENDPOINT_SUFFIX)
      @batch_subscribe_uri = create_batch_uri(:subscribe)
      @batch_unsubscribe_uri = create_batch_uri(:unsubscribe)

      @configuration = configuration.dup
      access_token_response = v1_authorize
      @access_token = access_token_response["access_token"]
      @access_token_expiry = Time.now.utc + access_token_response["expires_in"]
      @httpx = ::HTTPX.plugin(:auth).plugin(:persistent, configuration.httpx_options)
    end
    # rubocop:enable Metrics/MethodLength

    def push(body, headers: {})
      do_push_request(body, headers)
    end

    def subscribe(topic, *instance_ids, query: {}, headers: {})
      do_subscription_request(topic, *instance_ids, :subscribe, query, headers)
    end

    def unsubscribe(topic, *instance_ids, query: {}, headers: {})
      do_subscription_request(topic, *instance_ids, :unsubscribe, query, headers)
    end

    private

    def create_batch_uri(action)
      case action
      when :subscribe
        URI.join(topic_base_url, TOPIC_ENDPOINT_PREFIX + TOPIC_BATCH_SUBSCRIBE_SUFFIX)
      when :unsubscribe
        URI.join(topic_base_url, TOPIC_ENDPOINT_PREFIX + TOPIC_BATCH_UNSUBSCRIBE_SUFFIX)
      else
        raise ArgumentError, "Invalid action: #{action}. Use :subscribe or :unsubscribe."
      end
    end

    def v1_authorize
      @auth ||= if configuration.json_key_io
                  Google::Auth::ServiceAccountCredentials.make_creds(
                    json_key_io: prepare_json_key_io,
                    scope: configuration.scope
                  )
                else
                  # from ENV
                  Google::Auth::ServiceAccountCredentials.make_creds(scope: configuration.scope)
                end
      @auth.fetch_access_token
    end

    def prepare_json_key_io
      io = if configuration.json_key_io.respond_to?(:read)
             configuration.json_key_io
           else
             File.open(configuration.json_key_io)
           end
      io.rewind if io.respond_to?(:read)
      io
    end

    def do_push_request(json, headers)
      access_token_refresh
      send_request(@push_uri, json, headers)
    end

    def do_subscription_request(topic, *instance_ids, action, query, headers)
      access_token_refresh
      headers["access_token_auth"] = "true"

      uri = action == :subscribe ? @batch_subscribe_uri.dup : @batch_unsubscribe_uri.dup
      uri.query = URI.encode_www_form(query) unless query.empty?
      send_request(uri, make_subscription_body(topic, *instance_ids), headers)
    end

    def make_subscription_body(topic, *instance_ids)
      topic = topic.start_with?("/topics/") ? topic : "/topics/#{topic}"
      {
        to: topic,
        registration_tokens: instance_ids
      }
    end

    def send_request(uri, json, headers)
      httpx.bearer_auth(access_token).post(uri.to_s, json:, headers:).raise_for_status
    rescue HTTPX::Error => e
      raise Ffccmmx::HTTPXError, cause: e
    rescue StandardError => e
      raise Ffccmmx::Error, cause: e
    end

    def access_token_refresh
      # https://cloud.google.com/docs/authentication/token-types#at-lifetime
      # By default, access tokens are good for 1 hour (3,600 seconds).
      # When the access token has expired, your token management code must get a new one.
      return if access_token_expiry > Time.now.utc + 300

      access_token_response = v1_authorize
      @access_token = access_token_response["access_token"]
      @access_token_expiry = Time.now.utc + access_token_response["expires_in"]
    end
  end
end
