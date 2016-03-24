require 'spec_helper'

describe FunWithJsonApi::Exception do
  let(:message) { Faker::Lorem.sentence }
  let(:payload) { FunWithJsonApi::ExceptionPayload.new }
  subject(:instance) { described_class.new(message, payload) }

  describe '#message' do
    subject { instance.message }

    it 'returns the developer-only exception message' do
      expect(subject).to eq message
    end
  end

  describe '#payload' do
    subject { instance.payload }

    it 'wraps the payload in a array' do
      expect(subject).to eq [payload]
    end

    context 'with an array of exceptions payloads' do
      let(:payload) { Array.new(3) { FunWithJsonApi::ExceptionPayload.new } }

      it 'returns all exception payloads' do
        expect(subject).to eq payload
      end
    end
  end

  describe '#http_status' do
    subject { instance.http_status }

    it 'defaults to returning 400' do
      expect(subject).to eq 400
    end

    context 'with a payload with a status value' do
      let(:payload) { FunWithJsonApi::ExceptionPayload.new.tap { |p| p.status = '422' } }

      it 'returns the payload status value' do
        expect(subject).to eq 422
      end
    end

    context 'with mutiple payloads with a single status values' do
      let(:payload) do
        Array.new(3) { FunWithJsonApi::ExceptionPayload.new.tap { |p| p.status = '403' } }
      end

      it 'returns the common payload status value' do
        expect(subject).to eq 403
      end
    end

    context 'with mutiple payloads with multiple 400-based status values' do
      let(:payload) do
        Array.new(3) { |i| FunWithJsonApi::ExceptionPayload.new.tap { |p| p.status = "40#{i}" } }
      end

      it 'falls back to returning 400' do
        expect(subject).to eq 400
      end
    end

    context 'with mutiple payloads with multiple 500-based status values' do
      let(:payload) do
        Array.new(3) { |i| FunWithJsonApi::ExceptionPayload.new.tap { |p| p.status = "50#{i}" } }
      end

      it 'falls back to returning 500' do
        expect(subject).to eq 500
      end
    end
  end
end
