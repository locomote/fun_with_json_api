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

    context 'when the document contains an unsupported attribute' do
      before { allow(deserializer).to receive(:attributes).and_return([]) }

      it 'raises a UnknownAttribute error' do
        expect do
          subject
        end.to raise_error(FunWithJsonApi::Exceptions::UnknownAttribute) do |e|
          expect(e.payload.size).to eq 1

          payload = e.payload.first
          expect(payload.code).to eq 'unknown_attribute'
          expect(payload.pointer).to eq '/data/attributes/foobar'
          expect(payload.title).to eq(
            'Request json_api attribute is not valid for the current endpoint'
          )
          expect(payload.detail).to eq(
            "The provided attribute 'foobar' can not be assigned to a 'examples' resource"\
            ' from the current endpoint'
          )
          expect(payload.status).to eq '422'
        end
      end
    end
  end
end
