require 'spec_helper'

# Returns a FunWithJsonApi::Deserializer class with an attribute
#
# Equivalent of:
# ```
# class ExampleDeserializer < FunWithJsonApi::Deserializer
#   attribute #{attribute}, #{attribute_options}
# end
def deserializer_class_with_attribute(attribute, attribute_options = {})
  Class.new(FunWithJsonApi::Deserializer) do
    attribute attribute, attribute_options
  end
end

def deserializer_class_with_relationship(relationship, relationship_type, relationship_options = {})
  relationship_deserializer = Class.new(FunWithJsonApi::Deserializer) do
    type(relationship_type)
  end

  Class.new(FunWithJsonApi::Deserializer) do
    belongs_to relationship, relationship_deserializer, relationship_options
  end
end

# Returns an instance of a FunWithJsonApi::Deserializer with an attribute with an assigned value
#
# Equivalent of:
# ```
# class ExampleDeserializer < FunWithJsonApi::Deserializer
#   attribute #{attribute}, #{attribute_options}
# end
# ExampleDeserializer.create
# ~~~
def deserializer_with_attribute(attribute, attribute_options = {})
  deserializer_class_with_attribute(attribute, attribute_options).create
end

describe FunWithJsonApi::Deserializer do
  describe '.id_param' do
    context 'with no arguments' do
      it 'sets id_param to id for all new deserializer instances' do
        instance = Class.new(described_class).create
        expect(instance.id_param).to eq :id
        expect(instance.attributes.size).to eq 0
      end
    end
    context 'with a name argument' do
      it 'adds an aliased id attribute for all new deserializer instances' do
        instance = Class.new(described_class) do
          id_param :code
        end.create
        expect(instance.id_param).to eq :code
        expect(instance.attributes.size).to eq 0
      end
      it 'converts the name parameter to a symbol' do
        instance = Class.new(described_class) do
          id_param 'code'
        end.create
        expect(instance.id_param).to eq :code
        expect(instance.attributes.size).to eq 0
      end
    end
    context 'with a format argument' do
      it 'adds an id attribute with format to all new deserializer instances' do
        instance = Class.new(described_class) do
          id_param format: :integer
        end.create
        expect(instance.id_param).to eq :id
        expect(instance.attributes.size).to eq 1

        attribute = instance.attributes.first
        expect(attribute).to be_kind_of(FunWithJsonApi::Attributes::IntegerAttribute)
        expect(attribute.name).to eq :id
        expect(attribute.as).to eq :id
      end
    end
    context 'with a name and format argument' do
      it 'adds an aliased id attribute with format to all new deserializer instances' do
        instance = Class.new(described_class) do
          id_param :code, format: :uuid_v4
        end.create
        expect(instance.id_param).to eq :code
        expect(instance.attributes.size).to eq 1

        attribute = instance.attributes.first
        expect(attribute).to be_kind_of(FunWithJsonApi::Attributes::UuidV4Attribute)
        expect(attribute.name).to eq :id
        expect(attribute.as).to eq :code
      end
    end
  end

  describe '#parse_{attribute}' do
    context 'with an alias value' do
      it 'defines a parse method from the alias value' do
        deserializer = deserializer_with_attribute(:original_key, as: :assigned_key)
        expect(deserializer.parse_assigned_key('Foo Bar')).to eq 'Foo Bar'
        expect(deserializer).not_to respond_to(:original_key)
      end
    end

    context 'with no format argument (string)' do
      it 'allows a String value' do
        deserializer = deserializer_with_attribute(:example)
        expect(deserializer.parse_example('Foo Bar')).to eq 'Foo Bar'
      end
      it 'allows a nil value' do
        deserializer = deserializer_with_attribute(:example)
        expect(deserializer.parse_example(nil)).to be nil
      end
      it 'raises an InvalidAttribute error an for non string value' do
        deserializer = deserializer_with_attribute(:example)
        [1, true, false, [], {}].each do |value|
          expect do
            deserializer.parse_example(value)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidAttribute) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_attribute'
            expect(payload.title).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_attribute')
            )
            expect(payload.detail).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_string_attribute')
            )
            expect(payload.pointer).to eq '/data/attributes/example'
          end
        end
      end
    end

    context 'with a boolean format' do
      it 'allows a Boolean.TRUE value' do
        deserializer = deserializer_with_attribute(:example, format: :boolean)
        expect(deserializer.parse_example(true)).to eq true
      end
      it 'allows a Boolean.FALSE value' do
        deserializer = deserializer_with_attribute(:example, format: :boolean)
        expect(deserializer.parse_example(false)).to eq false
      end
      it 'allows a nil value' do
        deserializer = deserializer_with_attribute(:example, format: :boolean)
        expect(deserializer.parse_example(nil)).to be nil
      end
      it 'raises an InvalidAttribute error an for invalid boolean values' do
        deserializer = deserializer_with_attribute(:example, format: :boolean)
        ['true', 'True', 'TRUE', 1, 'false', 'False', 'FALSE', 0].each do |value|
          expect do
            deserializer.parse_example(value)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidAttribute) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_attribute'
            expect(payload.title).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_attribute')
            )
            expect(payload.detail).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_boolean_attribute')
            )
            expect(payload.pointer).to eq '/data/attributes/example'
          end
        end
      end
    end

    context 'with a date format' do
      it 'allows a "YYYY-MM-DD" formatted date String' do
        deserializer = deserializer_with_attribute(:example, format: :date)
        expect(deserializer.parse_example('2016-03-12')).to eq Date.new(2016, 03, 12)
      end
      it 'allows a nil value' do
        deserializer = deserializer_with_attribute(:example, format: :date)
        expect(deserializer.parse_example(nil)).to be nil
      end
      it 'raises an InvalidAttribute error an for invalid date value' do
        deserializer = deserializer_with_attribute(:example, format: :date)
        ['2016-12', 'Last Wednesday', 'April'].each do |value|
          expect do
            deserializer.parse_example(value)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidAttribute) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_attribute'
            expect(payload.title).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_attribute')
            )
            expect(payload.detail).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_date_attribute')
            )
            expect(payload.pointer).to eq '/data/attributes/example'
          end
        end
      end
    end

    context 'with a datetime format' do
      it 'allows a ISO 8601 formatted values' do
        deserializer = deserializer_with_attribute(:example, format: :datetime)
        [
          '2016-03-11T03:45:40+00:00',
          '2016-03-11T13:45:40+10:00',
          '2016-03-11T03:45:40Z',
          '20160311T034540Z'
        ].each do |timestamp|
          expect(deserializer.parse_example(timestamp)).to eq(
            DateTime.new(2016, 03, 11, 3, 45, 40, 0)
          )
        end
      end
      it 'allows a nil value' do
        deserializer = deserializer_with_attribute(:example, format: :datetime)
        expect(deserializer.parse_example(nil)).to be nil
      end
      it 'raises an InvalidAttribute error an for invalid date value' do
        deserializer = deserializer_with_attribute(:example, format: :datetime)
        [
          'Last Wednesday',
          'April'
        ].each do |value|
          expect do
            deserializer.parse_example(value)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidAttribute) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_attribute'
            expect(payload.title).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_attribute')
            )
            expect(payload.detail).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_datetime_attribute')
            )
            expect(payload.pointer).to eq '/data/attributes/example'
          end
        end
      end
    end

    context 'with a decimal format' do
      it 'allows integers' do
        deserializer = deserializer_with_attribute(:example, format: :decimal)
        expect(deserializer.parse_example(12)).to eq BigDecimal.new('12')
      end
      it 'allows floats' do
        deserializer = deserializer_with_attribute(:example, format: :decimal)
        expect(deserializer.parse_example(12.34)).to eq BigDecimal.new('12.34')
      end
      it 'allows integer numbers as strings' do
        deserializer = deserializer_with_attribute(:example, format: :decimal)
        expect(deserializer.parse_example('12')).to eq BigDecimal.new('12')
      end
      it 'allows floating point numbers as strings' do
        deserializer = deserializer_with_attribute(:example, format: :decimal)
        expect(deserializer.parse_example('12.30')).to eq BigDecimal.new('12.30')
      end
      it 'allows a nil value' do
        deserializer = deserializer_with_attribute(:example, format: :decimal)
        expect(deserializer.parse_example(nil)).to be nil
      end
      it 'raises an InvalidAttribute error an for invalid decimal value' do
        deserializer = deserializer_with_attribute(:example, format: :decimal)
        [
          'twelve',
          '-',
          'abc'
        ].each do |value|
          expect do
            deserializer.parse_example(value)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidAttribute) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_attribute'
            expect(payload.title).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_attribute')
            )
            expect(payload.detail).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_decimal_attribute')
            )
            expect(payload.pointer).to eq '/data/attributes/example'
          end
        end
      end
    end

    context 'with a float format' do
      it 'allows floats' do
        deserializer = deserializer_with_attribute(:example, format: :float)
        expect(deserializer.parse_example(12.34)).to eq 12.34
      end
      it 'allows float numbers as strings' do
        deserializer = deserializer_with_attribute(:example, format: :float)
        expect(deserializer.parse_example('12.34')).to eq 12.34
      end
      it 'allows integer numbers as strings' do
        deserializer = deserializer_with_attribute(:example, format: :float)
        expect(deserializer.parse_example('12')).to eq 12.0
      end
      it 'allows a nil value' do
        deserializer = deserializer_with_attribute(:example, format: :float)
        expect(deserializer.parse_example(nil)).to be nil
      end
      it 'raises an InvalidAttribute error an for invalid float value' do
        deserializer = deserializer_with_attribute(:example, format: :float)
        [
          'twelve',
          '-',
          'abc'
        ].each do |value|
          expect do
            deserializer.parse_example(value)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidAttribute) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_attribute'
            expect(payload.title).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_attribute')
            )
            expect(payload.detail).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_float_attribute')
            )
            expect(payload.pointer).to eq '/data/attributes/example'
          end
        end
      end
    end

    context 'with a integer format' do
      it 'allows integer numbers as strings' do
        deserializer = deserializer_with_attribute(:example, format: :integer)
        expect(deserializer.parse_example('12')).to eq BigDecimal.new('12')
      end
      it 'allows a nil value' do
        deserializer = deserializer_with_attribute(:example, format: :integer)
        expect(deserializer.parse_example(nil)).to be nil
      end
      it 'raises an InvalidAttribute error an for invalid integer value' do
        deserializer = deserializer_with_attribute(:example, format: :integer)
        [
          12.0,
          '12.0',
          'twelve',
          '-',
          'abc'
        ].each do |value|
          expect do
            deserializer.parse_example(value)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidAttribute) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_attribute'
            expect(payload.title).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_attribute')
            )
            expect(payload.detail).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_integer_attribute')
            )
            expect(payload.pointer).to eq '/data/attributes/example'
          end
        end
      end
    end

    context 'with a uuid_v4 format' do
      it 'allows uuid_v4 numbers as strings' do
        deserializer = deserializer_with_attribute(:example, format: :uuid_v4)
        expect(deserializer.parse_example('f47ac10b-58cc-4372-a567-0e02b2c3d479')).to eq(
          'f47ac10b-58cc-4372-a567-0e02b2c3d479'
        )
      end
      it 'allows a nil value' do
        deserializer = deserializer_with_attribute(:example, format: :uuid_v4)
        expect(deserializer.parse_example(nil)).to be nil
      end
      it 'raises an InvalidAttribute error an for invalid uuid_v4 value' do
        deserializer = deserializer_with_attribute(:example, format: :uuid_v4)
        [
          'abc',
          12.0,
          '12.0',
          '6ba7b810-9dad-11d1-80b4-00c04fd430c8', # RFC 4122 version 3
          'f47ac10b58cc4372a5670e02b2c3d479' # uuid without dashes
        ].each do |value|
          expect do
            deserializer.parse_example(value)
          end.to raise_error(FunWithJsonApi::Exceptions::InvalidAttribute) do |e|
            expect(e.payload.size).to eq 1

            payload = e.payload.first
            expect(payload.status).to eq '400'
            expect(payload.code).to eq 'invalid_attribute'
            expect(payload.title).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_attribute')
            )
            expect(payload.detail).to eq(
              I18n.t('fun_with_json_api.exceptions.invalid_uuid_v4_attribute')
            )
            expect(payload.pointer).to eq '/data/attributes/example'
          end
        end
      end
    end

    it 'raises an ArgumentError with an unknown format' do
      expect do
        deserializer_class_with_attribute(:example, format: :blarg)
      end.to raise_error(ArgumentError)
    end

    it 'raises an ArgumentError with a blank attribute name' do
      expect do
        deserializer_class_with_attribute('', format: :string)
      end.to raise_error(ArgumentError)
    end
  end

  describe '#parse_{relationship}_id' do
    context 'with a ARModels::Author relationship with a "code" id param' do
      let(:deserializer) do
        author_deserializer_class = Class.new(described_class) do
          id_param 'code'
          type 'persons'
          resource_class ARModels::Author
        end

        # Build the Deserializer
        Class.new(described_class) do
          belongs_to :example, author_deserializer_class
        end.create
      end

      it 'finds a resource by the defined id_param and returns the resource id' do
        author = ARModels::Author.create(id: 1, code: 'foobar')
        expect(deserializer.parse_example_id('foobar')).to eq author.id
      end

      it 'raises a MissingRelationship when unable to find the resource' do
        expect do
          deserializer.parse_example_id 'foobar'
        end.to raise_error(FunWithJsonApi::Exceptions::MissingRelationship) do |e|
          expect(e.message).to eq "Couldn't find ARModels::Author where code = \"foobar\""
          expect(e.payload.size).to eq 1

          payload = e.payload.first
          expect(payload.status).to eq '404'
          expect(payload.code).to eq 'missing_relationship'
          expect(payload.title).to eq 'Unable to find the requested relationship'
          expect(payload.pointer).to eq '/data/relationships/example'
          expect(payload.detail).to eq "Unable to find 'persons' with matching id: \"foobar\""
        end
      end

      it 'raises a InvalidRelationship when given an array value' do
        expect do
          deserializer.parse_example_id %w(1 2)
        end.to raise_error(FunWithJsonApi::Exceptions::InvalidRelationship) do |e|
          expect(e.payload.size).to eq 1

          payload = e.payload.first
          expect(payload.status).to eq '400'
          expect(payload.code).to eq 'invalid_relationship'
          expect(payload.title).to eq I18n.t('fun_with_json_api.exceptions.invalid_relationship')
          expect(payload.pointer).to eq '/data/relationships/example'
          expect(payload.detail).to be_kind_of(String)
        end
      end
    end
  end

  describe '#parse_{relationship}_ids' do
    context 'with a ARModels::Author relationship with a "code" id param' do
      let(:deserializer) do
        author_deserializer_class = Class.new(described_class) do
          id_param 'code'
          type 'persons'
          resource_class ARModels::Author
        end

        # Build the Deserializer
        Class.new(described_class) do
          has_many :examples, author_deserializer_class
        end.create
      end

      context 'with multiple resources' do
        let!(:author_a) { ARModels::Author.create(id: 1, code: 'foobar') }
        let!(:author_b) { ARModels::Author.create(id: 2, code: 'blargh') }

        context 'when all resources are authorised' do
          before do
            resource_authorizer = double(:resource_authorizer)
            allow(resource_authorizer).to receive(:call).and_return(true)
            allow(deserializer.relationship_for(:examples).deserializer).to(
              receive(:resource_authorizer).and_return(resource_authorizer)
            )
          end

          it 'finds a resource by the defined id_param and returns the resource id' do
            expect(deserializer.parse_example_ids(%w(foobar blargh))).to eq(
              [author_a.id, author_b.id]
            )
          end
        end

        context 'when a resource is not authorised' do
          before do
            resource_authorizer = double(:resource_authorizer)
            allow(resource_authorizer).to receive(:call).and_return(false)
            allow(resource_authorizer).to receive(:call).with(author_b).and_return(false)
            allow(resource_authorizer).to receive(:call).with(author_a).and_return(true)
            allow(deserializer.relationship_for(:examples).deserializer).to(
              receive(:resource_authorizer).and_return(resource_authorizer)
            )
          end

          it 'raises a UnauthorisedResource when unable to find a single resource' do
            expect do
              deserializer.parse_example_ids %w(foobar blargh)
            end.to raise_error(FunWithJsonApi::Exceptions::UnauthorisedResource) do |e|
              expect(e.payload.size).to eq 1

              payload = e.payload.first
              expect(payload.status).to eq '403'
              expect(payload.code).to eq 'unauthorized_resource'
              expect(payload.title).to eq 'Unable to access the requested resource'
              expect(payload.pointer).to eq '/data/relationships/examples/data/1'
              expect(payload.detail).to eq(
                "Unable to assign the requested 'persons' (blargh) to the current resource"
              )
            end
          end
        end
      end

      it 'raises a MissingRelationship when unable to find a single resource' do
        ARModels::Author.create(id: 1, code: 'foobar')

        expect do
          deserializer.parse_example_ids %w(foobar blargh)
        end.to raise_error(FunWithJsonApi::Exceptions::MissingRelationship) do |e|
          expect(e.message).to eq "Couldn't find ARModels::Author items with code in [\"blargh\"]"
          expect(e.payload.size).to eq 1

          payload = e.payload.first
          expect(payload.status).to eq '404'
          expect(payload.code).to eq 'missing_relationship'
          expect(payload.title).to eq 'Unable to find the requested relationship'
          expect(payload.pointer).to eq '/data/relationships/examples/data/1'
          expect(payload.detail).to eq "Unable to find 'persons' with matching id: \"blargh\""
        end
      end

      it 'raises a MissingRelationship with a payload for all missing resources' do
        expect do
          deserializer.parse_example_ids %w(foobar blargh)
        end.to raise_error(FunWithJsonApi::Exceptions::MissingRelationship) do |e|
          expect(e.message).to eq(
            "Couldn't find ARModels::Author items with code in [\"foobar\", \"blargh\"]"
          )
          expect(e.payload.size).to eq 2

          payload_a = e.payload.first
          expect(payload_a.status).to eq '404'
          expect(payload_a.code).to eq 'missing_relationship'
          expect(payload_a.title).to eq 'Unable to find the requested relationship'
          expect(payload_a.pointer).to eq '/data/relationships/examples/data/0'
          expect(payload_a.detail).to eq "Unable to find 'persons' with matching id: \"foobar\""

          payload_b = e.payload.last
          expect(payload_b.status).to eq '404'
          expect(payload_b.code).to eq 'missing_relationship'
          expect(payload_b.title).to eq 'Unable to find the requested relationship'
          expect(payload_b.pointer).to eq '/data/relationships/examples/data/1'
          expect(payload_b.detail).to eq "Unable to find 'persons' with matching id: \"blargh\""
        end
      end

      it 'raises a InvalidRelationship when given a non-array value' do
        expect do
          deserializer.parse_example_ids '1'
        end.to raise_error(FunWithJsonApi::Exceptions::InvalidRelationship) do |e|
          expect(e.payload.size).to eq 1

          payload = e.payload.first
          expect(payload.status).to eq '400'
          expect(payload.code).to eq 'invalid_relationship'
          expect(payload.title).to eq I18n.t('fun_with_json_api.exceptions.invalid_relationship')
          expect(payload.pointer).to eq '/data/relationships/examples'
          expect(payload.detail).to be_kind_of(String)
        end
      end
    end
  end
end
