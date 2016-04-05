require 'spec_helper'

describe FunWithJsonApi::SchemaValidators::CheckAttributes do
  describe '.call' do
    let(:document) do
      {
        'data' => {
          'id' => '42',
          'type' => 'examples',
          'attributes' => {
            'foobar' => 'blargh'
          }
        }
      }
    end
    let(:deserializer) { instance_double('FunWithJsonApi::Deserializer', type: 'examples') }
    subject { described_class.call(document, deserializer) }

    context 'when the document contains an attribute supported by the deserializer' do
      let(:attribute) { instance_double('FunWithJsonApi::Attribute', name: :foobar) }
      before { allow(deserializer).to receive(:attributes).and_return([attribute]) }

      it 'returns true' do
        expect(subject).to eq true
      end
    end

    context 'when the document contains an disabled attribute' do
      before do
        deserializer_class = class_double(
          'FunWithJsonApi::Deserializer',
          attribute_names: %i(foobar)
        )
        allow(deserializer).to receive(:class).and_return(deserializer_class)
        allow(deserializer).to receive(:attributes).and_return([])
      end

      it 'raises a UnknownAttribute error' do
        expect do
          subject
        end.to raise_error(FunWithJsonApi::Exceptions::UnknownAttribute) do |e|
          expect(e.http_status).to eq 403
          expect(e.payload.size).to eq 1

          payload = e.payload.first
          expect(payload.code).to eq 'unknown_attribute'
          expect(payload.pointer).to eq '/data/attributes/foobar'
          expect(payload.title).to eq(
            'Request json_api attribute is not recognised by the current endpoint'
          )
          expect(payload.detail).to eq(
            "The provided attribute 'foobar' can not be assigned to a 'examples' resource"\
            ' from the current endpoint'
          )
          expect(payload.status).to eq '403'
        end
      end
    end

    context 'when the document contains an unknown attribute' do
      before do
        deserializer_class = class_double(
          'FunWithJsonApi::Deserializer',
          attribute_names: %i(blargh)
        )
        allow(deserializer).to receive(:class).and_return(deserializer_class)
        allow(deserializer).to receive(:attributes).and_return([])
      end

      it 'raises a UnknownAttribute error' do
        expect do
          subject
        end.to raise_error(FunWithJsonApi::Exceptions::UnknownAttribute) do |e|
          expect(e.payload.size).to eq 1

          payload = e.payload.first
          expect(payload.code).to eq 'unknown_attribute'
          expect(payload.pointer).to eq '/data/attributes/foobar'
          expect(payload.title).to eq(
            'Request json_api attribute is not recognised by the current endpoint'
          )
          expect(payload.detail).to eq(
            "The provided attribute 'foobar' can not be assigned to a 'examples' resource"
          )
          expect(payload.status).to eq '400'
        end
      end
    end
  end
end
