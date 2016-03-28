require 'spec_helper'

describe FunWithJsonApi::DeserializerClassMethods do
  describe '.belongs_to' do
    it 'adds a Relationship attribute' do
      foos_deserializer_class = Class.new(FunWithJsonApi::Deserializer) do
        attribute :blargh
      end
      deserializer_class = Class.new(FunWithJsonApi::Deserializer) do
        belongs_to :foo, -> { foos_deserializer_class }
      end
      relationship = deserializer_class.relationships.last
      expect(relationship).to be_kind_of(FunWithJsonApi::Attributes::Relationship)

      expect(relationship.name).to eq :foo
      expect(relationship.as).to eq :foo
      expect(
        relationship.create_deserializer_with_options({})
      ).to be_kind_of(foos_deserializer_class)

      deserializer = relationship.create_deserializer_with_options({})
      expect(deserializer.attributes).to eq []
      expect(deserializer.relationships).to eq []
    end
  end

  describe '.has_many' do
    it 'adds a RelationshipCollection attribute' do
      foos_deserializer_class = Class.new(FunWithJsonApi::Deserializer) do
        attribute :blargh
      end
      deserializer_class = Class.new(FunWithJsonApi::Deserializer) do
        has_many :foos, -> { foos_deserializer_class }
      end
      relationship = deserializer_class.relationships.last
      expect(relationship).to be_kind_of(FunWithJsonApi::Attributes::RelationshipCollection)

      expect(relationship.name).to eq :foos
      expect(relationship.as).to eq :foo
      expect(
        relationship.create_deserializer_with_options({})
      ).to be_kind_of(foos_deserializer_class)

      deserializer = relationship.create_deserializer_with_options({})
      expect(deserializer.attributes).to eq []
      expect(deserializer.relationships).to eq []
    end

    it 'does not allow pluralized "as" values' do
      foos_deserializer_class = Class.new(FunWithJsonApi::Deserializer)
      expect do
        Class.new(FunWithJsonApi::Deserializer) do
          has_many :foos, -> { foos_deserializer_class }, as: 'foos'
        end.relationships
      end.to raise_error(ArgumentError, 'Use a singular relationship as value: {as: :foo}')
    end
  end
end
