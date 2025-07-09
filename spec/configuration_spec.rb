# frozen_string_literal: true

RSpec.describe "Ffccmmx::Configuration" do
  context "configuration" do
    before do
      Ffccmmx.reset_configuration
    end

    it "has default values" do
      config = Ffccmmx.configuration
      expect(config.scope).to eq(["https://www.googleapis.com/auth/firebase.messaging"])
      expect(config.json_key_io).to be_nil
      expect(config.httpx_options).to be_nil
    end

    it "allows configuration changes" do
      Ffccmmx.configure do |config|
        config.scope = ["https://www.googleapis.com/auth/cloud-platform"]
        config.json_key_io = StringIO.new('{"key": "value"}')
        config.httpx_options = HTTPX::Options.new
      end

      config = Ffccmmx.configuration
      expect(config.scope).to eq(["https://www.googleapis.com/auth/cloud-platform"])
      expect(config.json_key_io).not_to be_nil
      expect(config.httpx_options).to be_instance_of(HTTPX::Options)
    end
  end
end
