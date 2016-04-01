require 'spec_helper'

describe FunWithJsonApi::CollectionManager do
  subject(:instance) { described_class.new(collection, deserializer_class, deserializer_options) }
  let(:collection) { double('collection') }
  let(:deserializer_class) { class_double('FunWithJsonApi::Deserializer', type: 'examples') }
  let(:deserializer_options) { double('deserializer_options') }

  describe '#load_collection' do
    it 'calls FunWithJsonApi.load_collection with the document and the deserializers' do
      document = double('document')

      parsed_collection = double('parsed_collection')
      expect(FunWithJsonApi).to receive(:find_collection)
        .with(document, deserializer_class, deserializer_options)
        .and_return(parsed_collection)

      expect(instance.load_collection(document)).to eq parsed_collection
    end
  end

  describe '#report_invalid_resources_at_index!' do
    context 'with a resource index' do
      let(:resource_index) { 42 }

      context 'with a reason message as a string' do
        let(:reason_message) { Faker::Lorem.sentence }

        it 'raises a InvalidResource exception with the reason message as a detail' do
          expect do
            instance.report_invalid_resources_at_index! resource_index, reason_message
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidResource) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.code).to eq 'invalid_resource'
            expect(payload.title).to eq 'Unable to update the relationship with this resource'
            expect(payload.detail).to eq reason_message
            expect(payload.pointer).to eq '/data/42/id'
            expect(payload.status).to eq '422'
          end
        end
      end

      context 'with a reason message as a callable' do
        let(:reason_message) { Faker::Lorem.sentence }

        it 'raises a InvalidResource exception by invoking call with the resource index' do
          expect do
            instance.report_invalid_resources_at_index!(
              resource_index, ->(index) { "#{index}-#{reason_message}" }
            )
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidResource) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.code).to eq 'invalid_resource'
            expect(payload.title).to eq 'Unable to update the relationship with this resource'
            expect(payload.detail).to eq "42-#{reason_message}"
            expect(payload.pointer).to eq '/data/42/id'
            expect(payload.status).to eq '422'
          end
        end
      end

      context 'with a reason message not included' do
        it 'raises a InvalidResource exception with a default reason message' do
          expect do
            instance.report_invalid_resources_at_index! resource_index
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidResource) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.code).to eq 'invalid_resource'
            expect(payload.title).to eq 'Unable to update the relationship with this resource'
            expect(payload.detail).to eq "Unable to update the relationship with this 'examples'"
            expect(payload.pointer).to eq '/data/42/id'
            expect(payload.status).to eq '422'
          end
        end
      end
    end

    context 'with multiple resource indexes' do
      let(:resource_index) { [1, 3] }

      context 'with a reason message as a string' do
        let(:reason_message) { Faker::Lorem.sentence }

        it 'raises a InvalidResource exception with a payload for each index' do
          expect do
            instance.report_invalid_resources_at_index! resource_index, reason_message
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidResource) do |e|
            expect(e.payload.size).to eq 2

            payload = e.payload.first
            expect(payload.code).to eq 'invalid_resource'
            expect(payload.title).to eq 'Unable to update the relationship with this resource'
            expect(payload.detail).to eq reason_message
            expect(payload.pointer).to eq '/data/1/id'
            expect(payload.status).to eq '422'

            payload = e.payload.second
            expect(payload.code).to eq 'invalid_resource'
            expect(payload.title).to eq 'Unable to update the relationship with this resource'
            expect(payload.detail).to eq reason_message
            expect(payload.pointer).to eq '/data/3/id'
            expect(payload.status).to eq '422'
          end
        end
      end
    end
  end

  describe '#insert_records' do
    it 'raises a RelationshipNotSupported exception' do
      document = double('document')
      expect do
        instance.insert_records(document)
      end.to raise_error(FunWithJsonApi::Exceptions::RelationshipMethodNotSupported) do |e|
        expect(e.message).to eq(
          'Override FunWithJsonApi::CollectionManager#insert_records to implement insert'
        )
        expect(e.payload.size).to eq 1

        payload = e.payload.first
        expect(payload.code).to eq 'collection_method_not_supported'
        expect(payload.title).to eq 'The current relationship does not support this action'
        expect(payload.detail).to eq "Unable to insert 'examples' items from this endpoint"
        expect(payload.pointer).to eq nil
        expect(payload.status).to eq '403'
      end
    end
  end

  describe '#remove_records' do
    it 'raises a RelationshipNotSupported exception' do
      document = double('document')
      expect do
        instance.remove_records(document)
      end.to raise_error(FunWithJsonApi::Exceptions::RelationshipMethodNotSupported) do |e|
        expect(e.message).to eq(
          'Override FunWithJsonApi::CollectionManager#remove_records to implement remove'
        )
        expect(e.payload.size).to eq 1

        payload = e.payload.first
        expect(payload.code).to eq 'collection_method_not_supported'
        expect(payload.title).to eq 'The current relationship does not support this action'
        expect(payload.detail).to eq "Unable to remove 'examples' items from this endpoint"
        expect(payload.pointer).to eq nil
        expect(payload.status).to eq '403'
      end
    end
  end

  describe '#replace_all_records' do
    it 'raises a RelationshipNotSupported exception' do
      document = double('document')
      expect do
        instance.replace_all_records(document)
      end.to raise_error(FunWithJsonApi::Exceptions::RelationshipMethodNotSupported) do |e|
        expect(e.message).to eq(
          'Override FunWithJsonApi::CollectionManager#replace_all_records to implement replace all'
        )
        expect(e.payload.size).to eq 1

        payload = e.payload.first
        expect(payload.code).to eq 'collection_method_not_supported'
        expect(payload.title).to eq 'The current relationship does not support this action'
        expect(payload.detail).to eq "Unable to replace all 'examples' items from this endpoint"
        expect(payload.pointer).to eq nil
        expect(payload.status).to eq '403'
      end
    end
  end
end
