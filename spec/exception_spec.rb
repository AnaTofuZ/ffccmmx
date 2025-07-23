# frozen_string_literal: true

require "time"
require "ostruct"
require "ffccmmx/exceptions"
require "timecop"

RSpec.describe Ffccmmx::HTTPXRetryableError do
  describe "#response" do
    let(:response) { OpenStruct.new(status: 500, headers: { "retry-after" => "10" }) }
    let(:error) { described_class.new(response) }

    it "returns the response object" do
      expect(error.response).to eq(response)
    end
  end

  describe "#retry_time" do
    before do
      Timecop.freeze(Time.now)
    end
    after do
      Timecop.return
    end

    let(:response) { OpenStruct.new(headers: headers) }
    let(:error) { described_class.new(response) }

    context "when 'retry-after' header is present" do
      let(:headers) { { "retry-after" => "10" } }

      it "returns a Time object of the correct retry time" do
        current_time = Time.now
        allow(Time).to receive(:now).and_return(current_time)

        retry_time = error.retry_time

        expect(retry_time).to be_a(Time)
        expect(retry_time).to eq(current_time + 10)
      end
    end

    context "when 'retry-after' header is not present" do
      let(:headers) { {} }

      it "returns nil" do
        retry_time = error.retry_time
        expect(retry_time).to eq(Time.now + 2)
      end
    end

    context "when 'retry-after' header is invalid (non-integer value)" do
      let(:headers) { { "retry-after" => "invalid" } }

      it "returns the current time (retry immediately)" do
        current_time = Time.now
        allow(Time).to receive(:now).and_return(current_time)

        retry_time = error.retry_time
        expect(retry_time).to eq(current_time)
      end
    end

    context "when retry-after header is not present but use count" do
      let(:headers) { {} }

      it "returns a Time object of the correct retry time with count" do
        current_time = Time.now
        allow(Time).to receive(:now).and_return(current_time)

        retry_time = error.retry_time(count: 2)

        expect(retry_time).to be_a(Time)
        expect(retry_time).to eq(current_time + 2**2)
      end
    end
  end
end
