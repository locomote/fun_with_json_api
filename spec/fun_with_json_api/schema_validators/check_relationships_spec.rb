require 'spec_helper'

describe FunWithJsonApi::SchemaValidators::CheckRelationships do
  describe '.call' do
    let(:document) do
      {
        'data' => {
          'id' => '42',
          'type' => 'examples',
          'relationships' => {
            'foobar' => { 'id' => '24', 'type' => 'foobars' }
          }
        }
      }
    end
    let(:deserializer) { instance_double('FunWithJsonApi::Deserializer', type: 'examples') }
    subject { described_class.call(document, deserializer) }

    context 'when the document contains an relationships supported by the deserializer' do
      let(:relationship) { instance_double('FunWithJsonApi::Relationship', name: :foobar) }
      before { allow(deserializer).to receive(:relationships).and_return([relationship]) }

      it 'returns true' do
        expect(subject).to eq true
      end
    end

    context 'when the document contains an unsupported relationships' do
      before { allow(deserializer).to receive(:relationships).and_return([]) }

      it 'raises a UnknownRelationship error' do
        expect do
          subject
        end.to raise_error(FunWithJsonApi::Exceptions::UnknownRelationship) do |e|
          expect(e.payload.size).to eq 1

          payload = e.payload.first
          expect(payload.code).to eq 'unknown_relationship'
          expect(payload.pointer).to eq '/data/relationships/foobar'
          expect(payload.title).to eq(
            'Request json_api relationship is unsupported by the current endpoint'
          )
          expect(payload.detail).to eq(
            "The provided relationship 'foobar' can not be assigned to a 'examples' resource"\
            ' from the current endpoint'
          )
          expect(payload.status).to eq '422'
        end
      end
    end
  end
end
