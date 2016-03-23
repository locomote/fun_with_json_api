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
  describe '#parse_{attribute}' do
    context 'with an alias value' do
      it 'should generated an attribute from the alias value' do
        deserializer = deserializer_with_attribute(:original_key, as: :assigned_key)
        expect(deserializer.parse_assigned_key('Foo Bar')).to eq 'Foo Bar'
        expect(deserializer).to_not respond_to(:original_key)
      end
    end

    context 'with no format argument (string)' do
      it 'should allow a String value' do
        deserializer = deserializer_with_attribute(:example)
        expect(deserializer.parse_example('Foo Bar')).to eq 'Foo Bar'
      end
      it 'should allow a nil value' do
        deserializer = deserializer_with_attribute(:example)
        expect(deserializer.parse_example(nil)).to be nil
      end
    end

    context 'with a boolean format' do
      it 'should allow a Boolean.TRUE value' do
        deserializer = deserializer_with_attribute(:example, format: :boolean)
        expect(deserializer.parse_example(true)).to eq true
      end
      it 'should allow a Boolean.FALSE value' do
        deserializer = deserializer_with_attribute(:example, format: :boolean)
        expect(deserializer.parse_example(false)).to eq false
      end
      it 'should allow a nil value' do
        deserializer = deserializer_with_attribute(:example, format: :boolean)
        expect(deserializer.parse_example(nil)).to be nil
      end
      it 'should raise an ArgumentError for invalid boolean values' do
        deserializer = deserializer_with_attribute(:example, format: :boolean)
        ['true', 'True', 'TRUE', 1, 'false', 'False', 'FALSE', 0].each do |value|
          expect { deserializer.parse_example(value) }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with a date format' do
      it 'should allow a "YYYY-MM-DD" formatted value' do
        deserializer = deserializer_with_attribute(:example, format: :date)
        expect(deserializer.parse_example('2016-03-12')).to eq Date.new(2016, 03, 12)
      end
      it 'should allow a nil value' do
        deserializer = deserializer_with_attribute(:example, format: :date)
        expect(deserializer.parse_example(nil)).to be nil
      end
      it 'should raise an ArgumentError for invalid date value' do
        deserializer = deserializer_with_attribute(:example, format: :date)
        ['2016-12', 'Last Wednesday', 'April'].each do |value|
          expect { deserializer.parse_example(value) }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with a datetime format' do
      it 'should allow a ISO 8601 formatted values' do
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
      it 'should allow a nil value' do
        deserializer = deserializer_with_attribute(:example, format: :datetime)
        expect(deserializer.parse_example(nil)).to be nil
      end
      it 'should raise an ArgumentError for invalid date value' do
        deserializer = deserializer_with_attribute(:example, format: :datetime)
        [
          'Last Wednesday',
          'April'
        ].each do |value|
          expect { deserializer.parse_example(value) }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with a decimal format' do
      it 'should allow integer numbers as strings' do
        deserializer = deserializer_with_attribute(:example, format: :decimal)
        expect(deserializer.parse_example('12')).to eq BigDecimal.new('12')
      end
      it 'should allow floating point numbers as strings' do
        deserializer = deserializer_with_attribute(:example, format: :decimal)
        expect(deserializer.parse_example('12.30')).to eq BigDecimal.new('12.30')
      end
      it 'should allow a nil value' do
        deserializer = deserializer_with_attribute(:example, format: :decimal)
        expect(deserializer.parse_example(nil)).to be nil
      end
      xit 'should raise an ArgumentError for invalid decimal value' do
        deserializer = deserializer_with_attribute(:example, format: :decimal)
        [
          'twelve',
          '-',
          'abc'
        ].each do |value|
          expect { deserializer.parse_example(value) }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with a float format' do
      it 'should allow float numbers as strings' do
        deserializer = deserializer_with_attribute(:example, format: :float)
        expect(deserializer.parse_example('12.34')).to eq 12.34
      end
      it 'should allow integer numbers as strings' do
        deserializer = deserializer_with_attribute(:example, format: :float)
        expect(deserializer.parse_example('12')).to eq 12.0
      end
      it 'should allow a nil value' do
        deserializer = deserializer_with_attribute(:example, format: :float)
        expect(deserializer.parse_example(nil)).to be nil
      end
      it 'should raise an ArgumentError for invalid float value' do
        deserializer = deserializer_with_attribute(:example, format: :float)
        [
          'twelve',
          '-',
          'abc'
        ].each do |value|
          expect { deserializer.parse_example(value) }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with a integer format' do
      it 'should allow integer numbers as strings' do
        deserializer = deserializer_with_attribute(:example, format: :integer)
        expect(deserializer.parse_example('12')).to eq BigDecimal.new('12')
      end
      it 'should allow a nil value' do
        deserializer = deserializer_with_attribute(:example, format: :integer)
        expect(deserializer.parse_example(nil)).to be nil
      end
      it 'should raise an ArgumentError for invalid integer value' do
        deserializer = deserializer_with_attribute(:example, format: :integer)
        [
          '12.0',
          'twelve',
          '-',
          'abc'
        ].each do |value|
          expect { deserializer.parse_example(value) }.to raise_error(ArgumentError)
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
        author_deserializer_class = Class.new(FunWithJsonApi::Deserializer) do
          id_param 'code'
          type 'persons'
          resource_class ARModels::Author
        end

        # Build the Deserializer
        Class.new(FunWithJsonApi::Deserializer) do
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
          expect(e.message).to start_with "Couldn't find ARModels::Author where code = \"foobar\": "
          expect(e.payload.size).to eq 1

          payload = e.payload.first
          expect(payload.status).to eq '404'
          expect(payload.code).to eq 'missing_relationship'
          expect(payload.title).to eq I18n.t('fun_with_json_api.exceptions.missing_relationship')
          expect(payload.pointer).to eq '/data/relationships/example/id'
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
        author_deserializer_class = Class.new(FunWithJsonApi::Deserializer) do
          id_param 'code'
          type 'persons'
          resource_class ARModels::Author
        end

        # Build the Deserializer
        Class.new(FunWithJsonApi::Deserializer) do
          has_many :examples, author_deserializer_class
        end.create
      end

      it 'finds a resource by the defined id_param and returns the resource id' do
        author_a = ARModels::Author.create(id: 1, code: 'foobar')
        author_b = ARModels::Author.create(id: 2, code: 'blargh')
        expect(deserializer.parse_example_ids(%w(foobar blargh))).to eq(
          [author_a.id, author_b.id]
        )
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
          expect(payload.title).to eq I18n.t('fun_with_json_api.exceptions.missing_relationship')
          expect(payload.pointer).to eq '/data/relationships/examples/id'
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
          expect(payload_a.title).to eq I18n.t('fun_with_json_api.exceptions.missing_relationship')
          expect(payload_a.pointer).to eq '/data/relationships/examples/id'
          expect(payload_a.detail).to eq "Unable to find 'persons' with matching id: \"foobar\""

          payload_b = e.payload.last
          expect(payload_b.status).to eq '404'
          expect(payload_b.code).to eq 'missing_relationship'
          expect(payload_b.title).to eq I18n.t('fun_with_json_api.exceptions.missing_relationship')
          expect(payload_b.pointer).to eq '/data/relationships/examples/id'
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
