require 'spec_helper'

describe FunWithJsonApi::SchemaValidator do
  let(:document) { { data: { id: '42', type: 'examples' } } }
  let(:deserializer) { instance_double('FunWithJsonApi::Deserializer') }
  let(:resource) { double('Resource') }
  subject(:instance) { described_class.send :new, document, deserializer, resource }

  describe '.check' do
    subject { described_class.check(document, deserializer, resource) }

    it 'calls all schema validator checks with an instance of itself' do
      [
        FunWithJsonApi::SchemaValidators::CheckDocumentTypeMatchesResource,
        FunWithJsonApi::SchemaValidators::CheckDocumentIdMatchesResource
      ].each do |validator_check|
        expect(validator_check).to receive(:call).with(kind_of(described_class))
      end

      subject
    end
  end

  describe '#document_id' do
    subject { instance.document_id }

    context 'when the api document has symbolized keys' do
      context 'when the data attribute has an id value' do
        let(:document) { { data: { id: '42', type: 'examples' } } }

        it 'returns the /data/id value' do
          is_expected.to eq '42'
        end
      end
      context 'when the data attribute does not have an id value' do
        let(:document) { { data: { type: 'examples' } } }

        it { is_expected.to eq nil }
      end
    end
    context 'when the api document has string keys' do
      context 'when the data attribute has an id value' do
        let(:document) { { 'data' => { 'id' => '42', 'type' => 'examples' } } }

        it 'returns the /data/id value' do
          is_expected.to eq '42'
        end
      end
      context 'when the data attribute does not have an id value' do
        let(:document) { { 'data' => { 'type' => 'examples' } } }

        it { is_expected.to eq nil }
      end
    end
  end

  describe '#resource_id' do
    subject { instance.resource_id }

    context 'when the deserializer#id_param is :id' do
      before { allow(deserializer).to receive(:id_param).and_return(:id) }

      it 'returns the resource id as a string' do
        expect(resource).to receive(:id).and_return(42)
        expect(subject).to eq '42'
      end
    end
    context 'when the deserializer#id_param a field value' do
      before { allow(deserializer).to receive(:id_param).and_return(:code) }

      it 'returns the resource field value as a string' do
        expect(resource).to receive(:code).and_return('foobar')
        expect(subject).to eq 'foobar'
      end
    end
  end

  describe '#resource_type' do
    subject { instance.resource_type }

    it 'returns the deserializer type' do
      expect(deserializer).to receive(:type).and_return('examples')
      expect(subject).to eq 'examples'
    end
  end
end
