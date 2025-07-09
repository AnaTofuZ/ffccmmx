# frozen_string_literal: true

RSpec.describe Ffccmmx do
  let(:project_id) { ENV["TEST_FIREBASE_PROJECT_ID"] }
  let(:device_token) { ENV["TEST_DEVICE_TOKEN"] }
  let(:test_topic) { "/topics/test_topic" }

  before do
    Ffccmmx.reset_configuration
    Ffccmmx.configure do |config|
      config.json_key_io = StringIO.new(ENV["TEST_JSON"])
    end
    @client = Ffccmmx.new(project_id)
  end

  it "has a version number" do
    expect(Ffccmmx::VERSION).not_to be nil
  end

  describe "#push" do
    let(:notification_message) do
      {
        message: {
          token: device_token,
          notification: {
            title: "test title",
            body: "test body"
          }
        }
      }
    end

    it "successfully sends push notification" do
      response = @client.push(notification_message)

      expect(response.status).to eq(200)
      expect(response.json["name"]).to start_with("projects/#{project_id}/messages/")
      expect(response.version).to eq("2.0")
    end

    it "raises HTTPError on failure" do
      invalid_message = { message: { token: "invalid_token" } }

      expect { @client.push(invalid_message) }.to raise_error(Ffccmmx::HTTPXError) do |error|
        expect(error.cause.response.status).to eq(400)
      end
    end
  end

  describe "#subscribe" do
    it "successfully subscribes device to topic" do
      response = @client.subscribe(test_topic, device_token)

      expect(response.status).to eq(200)
      expect(response.json["results"]).to eq([{}])
      expect(response.version).to eq("2.0")
    end
  end

  describe "#unsubscribe" do
    it "successfully unsubscribes device from topic" do
      response = @client.unsubscribe(test_topic, device_token)

      expect(response.status).to eq(200)
      expect(response.json["results"]).to eq([{}])
      expect(response.version).to eq("2.0")
    end
  end
end
