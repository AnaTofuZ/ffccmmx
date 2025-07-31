# frozen_string_literal: true

require "webmock"
require "httpx/adapters/webmock"
require "webmock/rspec"
require "timecop"

WebMock.disable!

RSpec.describe Ffccmmx do
  before(:each) do
    WebMock.enable!
    Timecop.freeze(Time.now)
    Ffccmmx.reset_configuration
    allow(Google::Auth::ServiceAccountCredentials).to receive(:make_creds).and_return(
      instance_double("Google::Auth::ServiceAccountCredentials",
                      fetch_access_token: { "access_token" => "DUMMY_ACCESS_TOKEN_STRING", "expires_in" => 3600 })
    )

    WebMock.stub_request(:post, "https://www.googleapis.com/oauth2/v4/token")
           .with(
             body: {
               "assertion" => /.*/,
               "grant_type" => "urn:ietf:params:oauth:grant-type:jwt-bearer"
             },
             headers: {
               "Accept" => "*/*",
               "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
               "Content-Type" => "application/x-www-form-urlencoded",
               "User-Agent" => "Faraday v2.13.1"
             }
           ).to_return(
             status: 200,
             body: {
               access_token: "DUMMY_ACCESS_TOKEN_STRING",
               expires_in: 3599,
               token_type: "Bearer"
             }.to_json,
             headers: { "Content-Type" => "application/json" }
           )
  end

  after(:each) do
    WebMock.disable!
    Timecop.return
  end

  def mock_fcm_send_request(response_status:, response_body:)
    stub_request(:post, "https://fcm.googleapis.com/v1/projects/project_id/messages:send")
      .to_return(
        status: response_status,
        body: response_body.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def mock_fcm_subscription_request(topic:, tokens:, response_status:, response_body:)
    tokens = [tokens] unless tokens.is_a?(Array)
    stub_request(:post, "https://iid.googleapis.com/iid/v1:batchAdd")
      .with(
        body: {
          to: "/topics/#{topic}",
          registration_tokens: tokens
        }.to_json,
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip, deflate",
          "Access-Token-Auth" => "true",
          "Authorization" => "Bearer DUMMY_ACCESS_TOKEN_STRING",
          "Content-Type" => "application/json; charset=utf-8"
        }
      ).to_return(
        status: response_status,
        body: response_body.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def mock_fcm_unsubscription_request(topic:, tokens:, response_status:, response_body:)
    tokens = [tokens] unless tokens.is_a?(Array)
    stub_request(:post, "https://iid.googleapis.com/iid/v1:batchRemove")
      .with(
        body: {
          to: "/topics/#{topic}",
          registration_tokens: tokens
        }.to_json,
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip, deflate",
          "Access-Token-Auth" => "true",
          "Authorization" => "Bearer DUMMY_ACCESS_TOKEN_STRING",
          "Content-Type" => "application/json; charset=utf-8"
        }
      ).to_return(
        status: response_status,
        body: response_body.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def mock_concurrent_fcm_subscription_request(topic:, tokens:, response_status:, response_body:)
    tokens.each do |token|
      stub_request(:post, "https://iid.googleapis.com/iid/v1:batchAdd")
        .with(
          body: {
            to: "/topics/#{topic}",
            registration_tokens: [token]
          }.to_json,
          headers: {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip, deflate",
            "Access-Token-Auth" => "true",
            "Authorization" => "Bearer DUMMY_ACCESS_TOKEN_STRING",
            "Content-Type" => "application/json; charset=utf-8"
          }
        ).to_return(
          status: response_status,
          body: response_body.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end
  end

  def mock_concurrent_fcm_unsubscription_request(topic:, tokens:, response_status:, response_body:)
    tokens.each do |token|
      stub_request(:post, "https://iid.googleapis.com/iid/v1:batchRemove")
        .with(
          body: {
            to: "/topics/#{topic}",
            registration_tokens: [token]
          }.to_json,
          headers: {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip, deflate",
            "Access-Token-Auth" => "true",
            "Authorization" => "Bearer DUMMY_ACCESS_TOKEN_STRING",
            "Content-Type" => "application/json; charset=utf-8"
          }
        ).to_return(
          status: response_status,
          body: response_body.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end
  end

  describe "#push" do
    let(:notification_message) do
      {
        message: {
          token: "test_device_token",
          notification: {
            title: "test title",
            body: "test body"
          }
        }
      }
    end

    it "send successfully" do
      mock_fcm_send_request(
        response_status: 200,
        response_body: { name: "projects/project_id/messages/message_id" }
      )

      client = Ffccmmx.new("project_id")
      response = client.push(notification_message)

      expect(response.status).to eq(200)
      expect(response.json["name"]).to eq("projects/project_id/messages/message_id")
    end

    it "send with 400 non-retryable error" do
      mock_fcm_send_request(
        response_status: 400,
        response_body: { error: "Invalid request" }
      )

      client = Ffccmmx.new("project_id")
      expect { client.push(notification_message) }.to raise_error(Ffccmmx::HTTPXError) do |error|
        expect(error.cause).to be_a(HTTPX::HTTPError)
      end
    end

    it "send with 503 retryable error" do
      mock_fcm_send_request(
        response_status: 503,
        response_body: { error: "Service Unavailable" }
      )

      client = Ffccmmx.new("project_id")
      expect { client.push(notification_message) }.to raise_error(Ffccmmx::HTTPXRetryableError) do |error|
        expect(error.cause).to be_a(HTTPX::HTTPError)
      end
    end
  end

  describe "#concurrent_push" do
    let(:message_jsons) do
      [
        {
          message: {
            token: "test_device_token_1",
            notification: {
              title: "test title 1",
              body: "test body 1"
            }
          }
        },
        {
          message: {
            token: "test_device_token_2",
            notification: {
              title: "test title 2",
              body: "test body 2"
            }
          }
        }
      ]
    end

    it "sends multiple messages successfully" do
      mock_fcm_send_request(
        response_status: 200,
        response_body: { name: "projects/project_id/messages/message_id" }
      )

      client = Ffccmmx.new("project_id")
      response = client.concurrent_push(message_jsons)

      expect(response.size).to eq(2)
      response.each do |res|
        expect(res.value.status).to eq(200)
        expect(res.value.json["name"]).to start_with("projects/project_id/messages/")
        expect(res.value.version).to eq("2.0")
      end
    end

    it "handles retryable errors during concurrent push" do
      mock_fcm_send_request(
        response_status: 503,
        response_body: { error: "Service Unavailable" }
      )

      client = Ffccmmx.new("project_id")
      response = client.concurrent_push(message_jsons)
      expect(response.size).to eq(2)
      expect { response[-1].value }.to raise_error(Ffccmmx::HTTPXRetryableError) do |error|
        expect(error.cause).to be_a(HTTPX::HTTPError)
      end
    end

    it "handles non-retryable errors during concurrent push" do
      mock_fcm_send_request(
        response_status: 400,
        response_body: { error: "Invalid request" }
      )

      client = Ffccmmx.new("project_id")
      response = client.concurrent_push(message_jsons)
      expect(response.size).to eq(2)
      expect { response[-1].value }.to raise_error(Ffccmmx::HTTPXError) do |error|
        expect(error.cause).to be_a(HTTPX::HTTPError)
      end
    end

    it "send single message" do
      mock_fcm_send_request(
        response_status: 200,
        response_body: { name: "projects/project_id/messages/message_id" }
      )

      client = Ffccmmx.new("project_id")
      requests = [
        {
          message: {
            token: "test_device_token_1",
            notification: {
              title: "test title 1",
              body: "test body 1"
            }
          }
        }
      ]
      response = client.concurrent_push(requests)

      expect(response.size).to eq(1)
      response.each do |res|
        expect(res.value.status).to eq(200)
        expect(res.value.json["name"]).to start_with("projects/project_id/messages/")
        expect(res.value.version).to eq("2.0")
      end
    end
  end

  describe "#subscription" do
    let(:topic) { "test_topic" }
    let(:instance_ids) { %w[instance_id_1 instance_id_2] }

    it "subscribes to a topic successfully" do
      mock_fcm_subscription_request(
        topic: topic,
        tokens: instance_ids,
        response_status: 200,
        response_body: { success: true }
      )

      client = Ffccmmx.new("project_id")
      response = client.subscribe(topic, *instance_ids)

      expect(response.status).to eq(200)
      expect(response.json["success"]).to be true
    end

    it "handles errors during subscription" do
      mock_fcm_subscription_request(
        topic: topic,
        tokens: instance_ids,
        response_status: 400,
        response_body: { error: "Invalid request" }
      )

      client = Ffccmmx.new("project_id")
      expect { client.subscribe(topic, *instance_ids) }.to raise_error(Ffccmmx::HTTPXError) do |error|
        expect(error.cause).to be_a(HTTPX::HTTPError)
      end
    end
  end

  describe "#concurrent_subscription" do
    let(:topic) { "test_topic" }
    let(:instance_ids) { %w[instance_id_1 instance_id_2] }

    it "subscribes multiple instances to a topic concurrently" do
      mock_concurrent_fcm_subscription_request(
        topic: topic,
        tokens: instance_ids,
        response_status: 200,
        response_body: { success: true }
      )

      client = Ffccmmx.new("project_id")
      response = client.concurrent_subscribe(topic, *instance_ids)

      expect(response.size).to eq(2)
      response.each do |res|
        expect(res.value.status).to eq(200)
        expect(res.value.json["success"]).to be true
      end
    end

    it "handles errors during concurrent subscription" do
      mock_concurrent_fcm_subscription_request(
        topic: topic,
        tokens: instance_ids,
        response_status: 400,
        response_body: { error: "Invalid request" }
      )

      client = Ffccmmx.new("project_id")
      response = client.concurrent_subscribe(topic, *instance_ids)
      expect(response.size).to eq(2)
      expect { response[-1].value }.to raise_error(Ffccmmx::HTTPXError) do |error|
        expect(error.cause).to be_a(HTTPX::HTTPError)
      end
    end
  end
  describe "#unsubscription" do
    let(:topic) { "test_topic" }
    let(:instance_ids) { %w[instance_id_1 instance_id_2] }

    it "unsubscribes from a topic successfully" do
      mock_fcm_unsubscription_request(
        topic: topic,
        tokens: instance_ids,
        response_status: 200,
        response_body: { success: true }
      )

      client = Ffccmmx.new("project_id")
      response = client.unsubscribe(topic, *instance_ids)

      expect(response.status).to eq(200)
      expect(response.json["success"]).to be true
    end

    it "handles errors during unsubscription" do
      mock_fcm_unsubscription_request(
        topic: topic,
        tokens: instance_ids,
        response_status: 400,
        response_body: { error: "Invalid request" }
      )

      client = Ffccmmx.new("project_id")
      expect do
        client.unsubscribe(topic, *instance_ids)
      end.to raise_error(Ffccmmx::HTTPXError) do |error|
        expect(error.cause).to be_a(HTTPX::HTTPError)
      end
    end
  end

  describe "#concurrent_unsubscription" do
    let(:topic) { "test_topic" }
    let(:instance_ids) { %w[instance_id_1 instance_id_2] }

    it "unsubscribes multiple instances from a topic concurrently" do
      mock_concurrent_fcm_unsubscription_request(
        topic: topic,
        tokens: instance_ids,
        response_status: 200,
        response_body: { success: true }
      )

      client = Ffccmmx.new("project_id")
      response = client.concurrent_unsubscribe(topic, *instance_ids)

      expect(response.size).to eq(2)
      response.each do |res|
        expect(res.value.status).to eq(200)
        expect(res.value.json["success"]).to be true
      end
    end

    it "handles errors during concurrent unsubscription" do
      mock_concurrent_fcm_unsubscription_request(
        topic: topic,
        tokens: instance_ids,
        response_status: 400,
        response_body: { error: "Invalid request" }
      )

      client = Ffccmmx.new("project_id")
      response = client.concurrent_unsubscribe(topic, *instance_ids)
      expect(response.size).to eq(2)
      expect { response[-1].value }.to raise_error(Ffccmmx::HTTPXError) do |error|
        expect(error.cause).to be_a(HTTPX::HTTPError)
      end
    end
  end
end
