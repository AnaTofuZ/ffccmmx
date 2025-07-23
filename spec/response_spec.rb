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
      allow(httpx_exception).to receive(:response).and_return(response)
      allow(response).to receive(:raise_for_status).and_raise(httpx_exception)

      expect { Ffccmmx::Response.new(response).value }.to raise_error(Ffccmmx::HTTPXError)
    end

    it "httpx retryable exception" do
      response = instance_double("HTTPX::Response")
      allow(response).to receive(:status).and_return(500)
      allow(response).to receive(:headers).and_return({ "retry-after" => "10" })
      allow(response).to receive(:body).and_return(json: { "error" => "Server error" })

      httpx_exception = HTTPX::HTTPError.new(response)
      allow(response).to receive(:raise_for_status).and_raise(httpx_exception)

      expect { Ffccmmx::Response.new(response).value }.to raise_error(Ffccmmx::HTTPXRetryableError)
    end
  end
end
