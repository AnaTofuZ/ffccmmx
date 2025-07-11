# frozen_string_literal: true

RSpec.describe "Ffccmmx::Response" do
  context "value" do
    it "no exception value" do
      response = instance_double("HTTPX::Response",
                                 status: 400,
                                 json: { "error" => "Invalid token" })
      allow(response).to receive(:raise_for_status).and_return(response)
      expect(Ffccmmx::Response.new(response).value).to eq(response)
    end

    it "exception" do
      exception = Ffccmmx::Error.new("error")
      expect { Ffccmmx::Response.new(exception).value }.to raise_error(Ffccmmx::Error)
    end

    it "httpx exception" do
      response = instance_double("HTTPX::Response",
                                 status: 400,
                                 json: { "error" => "Invalid token" })
      httpx_exception = HTTPX::Error.new
      allow(response).to receive(:raise_for_status).and_raise(httpx_exception)

      expect { Ffccmmx::Response.new(response).value }.to raise_error(Ffccmmx::HTTPXError)
    end
  end
end
