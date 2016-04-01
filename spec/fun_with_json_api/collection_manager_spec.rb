require 'spec_helper'

describe FunWithJsonApi::CollectionManager do
  subject(:instance) { described_class.new(collection, deserializer_class, deserializer_options) }
  let(:collection) { double('collection') }
  let(:deserializer_class) { class_double('FunWithJsonApi::Deserializer', type: 'examples') }
  let(:deserializer_options) { double('deserializer_options') }
  let(:deserializer) { instance_double('FunWithJsonApi::Deserializer', type: 'examples') }
  before do
    allow(deserializer_class).to receive(:create)
      .with(deserializer_options)
      .and_return(deserializer)
  end

  describe '#insert_records' do
    context 'when a block is provided' do
      context 'when the block returns true for each item' do
        it 'loads a collection from the document and invokes the block with each collection item' do
          document = double('document')
          collection = [double('collection_a'), double('collection_b')]
          expect(
            FunWithJsonApi::FindCollectionFromDocument
          ).to receive(:find).with(document, deserializer).and_return(collection)

          received_items = []
          instance.insert_records(document) do |item|
            received_items << item
            true
          end
          expect(received_items).to eq collection
        end
      end
      context 'when the block returns false for an item' do
        it 'raises a FunWithJsonApi::Exceptions::InvalidResource with a payload for each item' do
          document = double('document')
          collection = [
            double('collection_a', success?: true),
            double('collection_b', success?: false)
          ]
          allow(
            FunWithJsonApi::FindCollectionFromDocument
          ).to receive(:find).with(document, deserializer).and_return(collection)
          allow(deserializer).to receive(:format_resource_id).with(collection[0]).and_return('id_a')
          allow(deserializer).to receive(:format_resource_id).with(collection[1]).and_return('id_b')

          expect do
            instance.insert_records(
              document,
              ->(index) { "Record '#{index}' is invalid" },
              &:success? # Call success on each collection items
            )
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidResource) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.code).to eq 'invalid_resource'
            expect(payload.title).to eq 'Unable to update the relationship with this resource'
            expect(payload.detail).to eq "Record 'id_b' is invalid"
            expect(payload.pointer).to eq '/data/1/id'
            expect(payload.status).to eq '422'
          end
        end
      end
    end

    context 'when no block is provided' do
      it 'raises a RelationshipNotSupported exception' do
        document = double('document')
        expect do
          instance.insert_records(document)
        end.to raise_error(FunWithJsonApi::Exceptions::RelationshipMethodNotSupported) do |e|
          expect(e.message).to eq(
            'Override FunWithJsonApi::CollectionManager#insert_records or supply a block'
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
  end

  describe '#remove_records' do
    context 'when a block is provided' do
      context 'when the block returns true for each item' do
        it 'loads a collection from the document and invokes the block with each collection item' do
          document = double('document')
          collection = [double('collection_a'), double('collection_b')]
          expect(
            FunWithJsonApi::FindCollectionFromDocument
          ).to receive(:find).with(document, deserializer).and_return(collection)

          received_items = []
          instance.remove_records(document) do |item|
            received_items << item
            true
          end
          expect(received_items).to eq collection
        end
      end
      context 'when the block returns false for an item' do
        it 'raises a FunWithJsonApi::Exceptions::InvalidResource with a payload for each item' do
          document = double('document')
          collection = [
            double('collection_a', success?: true),
            double('collection_b', success?: false)
          ]
          allow(
            FunWithJsonApi::FindCollectionFromDocument
          ).to receive(:find).with(document, deserializer).and_return(collection)
          allow(deserializer).to receive(:format_resource_id).with(collection[0]).and_return('id_a')
          allow(deserializer).to receive(:format_resource_id).with(collection[1]).and_return('id_b')

          expect do
            instance.remove_records(
              document,
              ->(index) { "Record '#{index}' is invalid" },
              &:success? # Call success on each collection items
            )
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidResource) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.code).to eq 'invalid_resource'
            expect(payload.title).to eq 'Unable to update the relationship with this resource'
            expect(payload.detail).to eq "Record 'id_b' is invalid"
            expect(payload.pointer).to eq '/data/1/id'
            expect(payload.status).to eq '422'
          end
        end
      end
    end

    context 'when no block is provided' do
      it 'raises a RelationshipNotSupported exception' do
        document = double('document')
        expect do
          instance.remove_records(document)
        end.to raise_error(FunWithJsonApi::Exceptions::RelationshipMethodNotSupported) do |e|
          expect(e.message).to eq(
            'Override FunWithJsonApi::CollectionManager#remove_records or supply a block'
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
  end

  describe '#replace_all_records' do
    context 'when no block is provided' do
      it 'raises a RelationshipNotSupported exception' do
        document = double('document')
        expect do
          instance.replace_all_records(document)
        end.to raise_error(FunWithJsonApi::Exceptions::RelationshipMethodNotSupported) do |e|
          expect(e.message).to eq(
            'Override FunWithJsonApi::CollectionManager#replace_all_records'\
            ' to implement replace all'
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

  describe '#raise_invalid_resource_exception' do
    before do
      allow(deserializer).to receive(:format_resource_id, &:id_value)
    end

    context 'with a invalid resource at an index' do
      let(:resource_index) { '42' }
      let(:invalid_resource) { double('invalid_resource', id_value: 'id_1') }

      context 'with a reason message as a string' do
        let(:reason_message) { Faker::Lorem.sentence }

        it 'raises a InvalidResource exception with the reason message as a detail' do
          expect do
            instance.send :raise_invalid_resource_exception,
                          { 42 => invalid_resource },
                          reason_message
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
            instance.send :raise_invalid_resource_exception,
                          { 42 => invalid_resource },
                          ->(index) { "#{index}-#{reason_message}" }
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidResource) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.code).to eq 'invalid_resource'
            expect(payload.title).to eq 'Unable to update the relationship with this resource'
            expect(payload.detail).to eq "id_1-#{reason_message}"
            expect(payload.pointer).to eq '/data/42/id'
            expect(payload.status).to eq '422'
          end
        end
      end

      context 'with a nil reason message' do
        it 'raises a InvalidResource exception with a default reason message' do
          expect do
            instance.send :raise_invalid_resource_exception, { 42 => invalid_resource }, nil
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidResource) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.code).to eq 'invalid_resource'
            expect(payload.title).to eq 'Unable to update the relationship with this resource'
            expect(payload.detail).to eq(
              "Unable to update relationship with 'examples' resource: 'id_1'"
            )
            expect(payload.pointer).to eq '/data/42/id'
            expect(payload.status).to eq '422'
          end
        end
      end
    end

    context 'with multiple resource indexes' do
      let(:resource_hash) do
        {
          1 => double('resource_a', id_value: 'id_a'),
          3 => double('resource_b', id_value: 'id_b')
        }
      end

      context 'with a reason message as a string' do
        let(:reason_message) { Faker::Lorem.sentence }

        it 'raises a InvalidResource exception with a payload for each index' do
          expect do
            instance.send :raise_invalid_resource_exception, resource_hash, reason_message
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
end
