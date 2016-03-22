require 'spec_helper'

describe FunWithJsonApi::PreDeserializer do
  describe '.parse' do
    describe 'document attributes parsing' do
      it 'should pass through attribute values' do
        deserializer = Class.new(FunWithJsonApi::Deserializer) do
          attribute :foo
        end.create

        document = {
          data: {
            attributes: {
              foo: 'bar'
            }
          }
        }.deep_stringify_keys!

        expect(FunWithJsonApi::PreDeserializer.parse(document, deserializer)).to eq(
          foo: 'bar'
        )
      end
      it 'should handle renamed attributes' do
        deserializer = Class.new(FunWithJsonApi::Deserializer) do
          attribute :foo, as: :blargh
        end.create

        document = {
          data: {
            attributes: {
              foo: 'bar'
            }
          }
        }.deep_stringify_keys!

        expect(FunWithJsonApi::PreDeserializer.parse(document, deserializer)).to eq(
          blargh: 'bar'
        )
      end
      it 'should only return known attributes' do
        deserializer = Class.new(FunWithJsonApi::Deserializer) do
          attribute :foo
        end.create

        document = {
          data: {
            attributes: {
              foo: 'bar',
              blargh: 'baz'
            }
          }
        }.deep_stringify_keys!

        expect(FunWithJsonApi::PreDeserializer.parse(document, deserializer)).to eq(
          foo: 'bar'
        )
      end
    end

    describe 'single relationship parsing' do
      it 'should pass through relationship values with a _id suffix' do
        foo_deserializer_class = Class.new(FunWithJsonApi::Deserializer)
        deserializer = Class.new(FunWithJsonApi::Deserializer) do
          belongs_to :foo, foo_deserializer_class
        end.create

        document = {
          data: {
            relationships: {
              foo: {
                data: { id: '42', type: 'foos' }
              }
            }
          }
        }.deep_stringify_keys!

        expect(FunWithJsonApi::PreDeserializer.parse(document, deserializer)).to eq(
          foo_id: '42'
        )
      end
      it 'should handle renamed relationships' do
        foo_deserializer_class = Class.new(FunWithJsonApi::Deserializer)
        deserializer = Class.new(FunWithJsonApi::Deserializer) do
          belongs_to :foo, foo_deserializer_class, as: :blargh
        end.create

        document = {
          data: {
            relationships: {
              foo: {
                data: { id: '42', type: 'foos' }
              }
            }
          }
        }.deep_stringify_keys!

        expect(FunWithJsonApi::PreDeserializer.parse(document, deserializer)).to eq(
          blargh_id: '42'
        )
      end
      it 'should only return known relationships' do
        foo_deserializer_class = Class.new(FunWithJsonApi::Deserializer)
        deserializer = Class.new(FunWithJsonApi::Deserializer) do
          belongs_to :foo, foo_deserializer_class
        end.create

        document = {
          data: {
            relationships: {
              foo: {
                data: { id: '42', type: 'foos' }
              },
              blargh: {
                data: { id: '24', type: 'blarghs' }
              }
            }
          }
        }.deep_stringify_keys!

        expect(FunWithJsonApi::PreDeserializer.parse(document, deserializer)).to eq(
          foo_id: '42'
        )
      end
    end

    describe 'relationship collection parsing' do
      it 'should pass through singular relationship values with a _ids suffix' do
        foo_deserializer_class = Class.new(FunWithJsonApi::Deserializer)
        deserializer = Class.new(FunWithJsonApi::Deserializer) do
          has_many :foo, foo_deserializer_class
        end.create

        document = {
          data: {
            relationships: {
              foo: {
                data: [{ id: '42', type: 'foos' }, { id: '24', type: 'foos' }]
              }
            }
          }
        }.deep_stringify_keys!

        expect(FunWithJsonApi::PreDeserializer.parse(document, deserializer)).to eq(
          foo_ids: %w(42 24)
        )
      end
      it 'should handle renamed relationships' do
        foo_deserializer_class = Class.new(FunWithJsonApi::Deserializer)
        deserializer = Class.new(FunWithJsonApi::Deserializer) do
          has_many :foo, foo_deserializer_class, as: :blargh
        end.create

        document = {
          data: {
            relationships: {
              foo: {
                data: [{ id: '42', type: 'foos' }, { id: '11', type: 'foos' }]
              }
            }
          }
        }.deep_stringify_keys!

        expect(FunWithJsonApi::PreDeserializer.parse(document, deserializer)).to eq(
          blargh_ids: %w(42 11)
        )
      end
      it 'should only return known relationships' do
        foo_deserializer_class = Class.new(FunWithJsonApi::Deserializer)
        deserializer = Class.new(FunWithJsonApi::Deserializer) do
          has_many :foo, foo_deserializer_class
        end.create

        document = {
          data: {
            relationships: {
              foo: {
                data: [{ id: '42', type: 'foos' }]
              },
              blargh: {
                data: [{ id: '24', type: 'blarghs' }]
              }
            }
          }
        }.deep_stringify_keys!

        expect(FunWithJsonApi::PreDeserializer.parse(document, deserializer)).to eq(
          foo_ids: ['42']
        )
      end
    end

    describe 'parser exceptions' do
      it 'should handle an invalid /data values' do
        deserializer = Class.new(FunWithJsonApi::Deserializer).create
        [
          nil,
          {},
          {
            'data' => nil
          }
        ].each do |document|
          expect do
            FunWithJsonApi::PreDeserializer.parse(document, deserializer)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidDocument) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_document'
            expect(payload.title).to eq I18n.t('fun_with_json_api.exceptions.invalid_document')
            expect(payload.pointer).to eq '/data'
            expect(payload.detail).to be_kind_of(String)
          end
        end
      end
      it 'should handle invalid /data/attributes values' do
        deserializer = Class.new(FunWithJsonApi::Deserializer).create
        [
          {
            'data' => { 'attributes' => [] }
          }
        ].each do |document|
          expect do
            FunWithJsonApi::PreDeserializer.parse(document, deserializer)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidDocument) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_document'
            expect(payload.title).to eq I18n.t('fun_with_json_api.exceptions.invalid_document')
            expect(payload.pointer).to eq '/data/attributes'
            expect(payload.detail).to be_kind_of(String)
          end
        end
      end
      it 'should handle invalid /data/relationships values' do
        deserializer = Class.new(FunWithJsonApi::Deserializer).create
        [
          {
            'data' => { 'relationships' => [] }
          }
        ].each do |document|
          expect do
            FunWithJsonApi::PreDeserializer.parse(document, deserializer)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidDocument) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_document'
            expect(payload.title).to eq I18n.t('fun_with_json_api.exceptions.invalid_document')
            expect(payload.pointer).to eq '/data/relationships'
            expect(payload.detail).to be_kind_of(String)
          end
        end
      end
      it 'should handle a invalid relationship value' do
        deserializer = Class.new(FunWithJsonApi::Deserializer).create
        [
          {
            'data' => {
              'relationships' => { 'rel' => nil }
            }
          }, {
            'data' => {
              'relationships' => { 'rel' => {} }
            }
          }
        ].each do |document|
          expect do
            FunWithJsonApi::PreDeserializer.parse(document, deserializer)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidDocument) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_document'
            expect(payload.title).to eq I18n.t('fun_with_json_api.exceptions.invalid_document')
            expect(payload.pointer).to eq '/data/relationships/rel'
            expect(payload.detail).to be_kind_of(String)
          end
        end
      end
    end
  end
end
