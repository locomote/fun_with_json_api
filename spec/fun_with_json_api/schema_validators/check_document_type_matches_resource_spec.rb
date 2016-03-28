require 'spec_helper'

describe FunWithJsonApi::SchemaValidators::CheckDocumentTypeMatchesResource do
  describe '.call' do
    let(:schema_validator) do
      instance_double('FunWithJsonApi::SchemaValidator')
    end
    subject { described_class.call(schema_validator) }

    context 'when document_type does not match resource_type' do
      before do
        allow(schema_validator).to receive(:document_type).and_return('examples')
        allow(schema_validator).to receive(:resource_type).and_return('foobar')
      end

      it 'raises a InvalidDocumentType error' do
        expect { subject }.to raise_error(FunWithJsonApi::Exceptions::InvalidDocumentType) do |e|
          expect(e.payload.size).to eq 1

          payload = e.payload.first
          expect(payload.code).to eq 'invalid_document_type'
          expect(payload.pointer).to eq '/data/type'
          expect(payload.title).to eq 'Request json_api data type does not match endpoint'
          expect(payload.detail).to eq "Expected data type to be a 'foobar' resource"
          expect(payload.status).to eq '409'
        end
      end
    end
  end
end
