require 'spec_helper'

describe FunWithJsonApi::SchemaValidators::CheckDocumentIdMatchesResource do
  describe '.call' do
    let(:schema_validator) do
      instance_double('FunWithJsonApi::SchemaValidator', resource_type: 'examples')
    end
    subject { described_class.call(schema_validator) }

    context 'when the resource is persisted' do
      let(:resource) { instance_double('ActiveRecord::Base', persisted?: true) }
      before { allow(schema_validator).to receive(:resource).and_return(resource) }

      context 'when /data/id does not match the resource id' do
        before do
          allow(schema_validator).to receive(:resource_id).and_return('11')
          allow(schema_validator).to receive(:document_id).and_return('42')
        end

        it 'raises a InvalidDocumentIdentifier error' do
          expect do
            subject
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidDocumentIdentifier) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.code).to eq 'invalid_document_identifier'
            expect(payload.pointer).to eq '/data/id'
            expect(payload.title).to eq 'Request json_api data id is invalid'
            expect(payload.detail).to eq 'Expected data id to match resource at endpoint: 11'
            expect(payload.status).to eq '409'
          end
        end
      end
    end

    context 'when the resource is not persisted' do
      let(:resource) { instance_double('ActiveRecord::Base', persisted?: false) }
      before { allow(schema_validator).to receive(:resource).and_return(resource) }

      context 'when a document_id has been supplied' do
        before { allow(schema_validator).to receive(:document_id).and_return('42') }

        context 'when the deserializer does not have an id attribute' do
          let(:deserializer) { instance_double('FunWithJsonApi::Deserializer') }
          before do
            allow(schema_validator).to receive(:deserializer).and_return(deserializer)
            allow(deserializer).to receive(:attributes).and_return([])
          end

          it 'raises a IllegalClientGeneratedIdentifier error' do
            expect do
              subject
            end.to raise_error(FunWithJsonApi::Exceptions::IllegalClientGeneratedIdentifier) do |e|
              expect(e.payload.size).to eq 1

              payload = e.payload.first
              expect(payload.code).to eq 'illegal_client_generated_identifier'
              expect(payload.pointer).to eq '/data/id'
              expect(payload.title).to eq(
                'Request json_api attempted to set an unsupported client-generated id'
              )
              expect(payload.detail).to eq(
                "The current endpoint does not allow you to set an id for a new 'examples' resource"
              )
              expect(payload.status).to eq '403'
            end
          end
        end
        context 'when the deserializer has an id attribute' do
          let(:deserializer) { instance_double('FunWithJsonApi::Deserializer') }
          before do
            allow(schema_validator).to receive(:deserializer).and_return(deserializer)
            allow(deserializer).to receive(:attributes).and_return(
              [
                instance_double('FunWithJsonApi::Attribute', name: :id)
              ]
            )
          end

          context 'when a resource matching id exists' do
            before do
              allow(deserializer).to receive(:load_resource_from_id_value)
                .with('42')
                .and_return(double('existing_resource', id: '24'))
            end

            it 'raises a InvalidClientGeneratedIdentifier error' do
              expect do
                subject
              end.to raise_error(
                FunWithJsonApi::Exceptions::InvalidClientGeneratedIdentifier
              ) do |e|
                expect(e.payload.size).to eq 1

                payload = e.payload.first
                expect(payload.code).to eq 'invalid_client_generated_identifier'
                expect(payload.pointer).to eq '/data/id'
                expect(payload.title).to eq(
                  'Request json_api data id has already been used for an existing'\
                  ' resource'
                )
                expect(payload.detail).to eq(
                  "The provided id for a new 'examples' resource has already been used by another"\
                  ' resource: 42'
                )
                expect(payload.status).to eq '409'
              end
            end
          end
        end
      end
    end
  end
end
