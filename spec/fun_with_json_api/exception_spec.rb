require 'spec_helper'

describe FunWithJsonApi::Exception do
  let(:message) { Faker::Lorem.sentence }
  let(:payload) { FunWithJsonApi::ExceptionPayload.new }
  subject(:instance) { described_class.new(message, payload) }

  describe '#message' do
    subject { instance.message }

    it 'should return the developer-only message' do
      expect(subject).to eq message
    end
  end

  describe '#payload' do
    subject { instance.payload }

    it 'should wrap the payload in a array' do
      expect(subject).to eq [payload]
    end

    context 'with an array of payloads' do
      let(:payload) { Array.new(3) { FunWithJsonApi::ExceptionPayload.new } }

      it 'should return the payload array' do
        expect(subject).to eq payload
      end
    end
  end

  describe '#http_status' do
    subject { instance.http_status }

    it 'should default to 400' do
      expect(subject).to eq 400
    end

    context 'with a payload with a status value' do
      let(:payload) { FunWithJsonApi::ExceptionPayload.new.tap { |p| p.status = '422' } }

      it 'should return the payload status' do
        expect(subject).to eq 422
      end
    end

    context 'with mutiple payloads with a single status values' do
      let(:payload) do
        Array.new(3) { FunWithJsonApi::ExceptionPayload.new.tap { |p| p.status = '403' } }
      end

      it 'should return the common payload status value' do
        expect(subject).to eq 403
      end
    end

    context 'with mutiple payloads with multiple 400-based status values' do
      let(:payload) do
        Array.new(3) { |i| FunWithJsonApi::ExceptionPayload.new.tap { |p| p.status = "40#{i}" } }
      end

      it 'should fall back to 400' do
        expect(subject).to eq 400
      end
    end

    context 'with mutiple payloads with multiple 500-based status values' do
      let(:payload) do
        Array.new(3) { |i| FunWithJsonApi::ExceptionPayload.new.tap { |p| p.status = "50#{i}" } }
      end

      it 'should fall back to 500' do
        expect(subject).to eq 500
      end
    end
  end
end
