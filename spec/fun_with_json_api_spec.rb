require 'spec_helper'

describe FunWithJsonApi do
  it 'has a semantic-versioning compatible VERSION' do
    # based on https://github.com/npm/node-semver/issues/32
    version_regex = /
      \A([0-9]+) # major
      \.([0-9]+) # minor
      \.([0-9]+) # patch
      (?:-([0-9A-Za-z-]+(?:\.[0-9a-z-]+)*))? # build
      (?:\+[0-9a-z-]+)?\z # tag
    /x
    expect(FunWithJsonApi::VERSION).to match(version_regex)
  end

  describe '.deserialize' do
    context 'with an PostDeserializer' do
      it 'converts a json api document into create post params' do
        ARModels::Author.create(id: 9)
        ARModels::Comment.create(id: 5)
        ARModels::Comment.create(id: 12)

        post_json = {
          'data': {
            'type': 'posts',
            'attributes': {
              'title': 'Rails is Omakase',
              'body': 'This is my post body'
            },
            'relationships': {
              'author': {
                'data': { 'type': 'person', 'id': '9' }
              },
              'comments': {
                'data': [
                  { 'type': 'comments', 'id': '5' },
                  { 'type': 'comments', 'id': '12' }
                ]
              }
            }
          }
        }

        post_params = described_class.deserialize(post_json, ARModels::PostDeserializer)
        expect(post_params).to eq(
          title: 'Rails is Omakase',
          body: 'This is my post body',
          author_id: 9,
          comment_ids: [5, 12]
        )
      end
      it 'converts a json api document into update post params' do
        post = ARModels::Post.create(id: 1)
        ARModels::Author.create(id: 9)
        ARModels::Comment.create(id: 5)
        ARModels::Comment.create(id: 12)

        post_json = {
          'data': {
            'type': 'posts',
            'id': '1',
            'attributes': {
              'title': 'Rails is Omakase',
              'body': 'This is my post body'
            },
            'relationships': {
              'author': {
                'data': { 'type': 'person', 'id': '9' }
              },
              'comments': {
                'data': [
                  { 'type': 'comments', 'id': '5' },
                  { 'type': 'comments', 'id': '12' }
                ]
              }
            }
          }
        }

        post_params = described_class.deserialize(post_json, ARModels::PostDeserializer, post)
        expect(post_params).to eq(
          title: 'Rails is Omakase',
          body: 'This is my post body',
          author_id: 9,
          comment_ids: [5, 12]
        )
      end
      it 'allows for relationships to be scoped' do
        post = ARModels::Post.create(id: 1)
        ARModels::Author.create(id: 9, name: 'John', code: 'foo')
        ARModels::Author.create(id: 10, name: 'John', code: 'bar')
        ARModels::Comment.create(id: 5)
        ARModels::Comment.create(id: 12)

        post_json = {
          'data': {
            'type': 'posts',
            'id': '1',
            'attributes': {
              'title': 'Rails is Omakase',
              'body': 'This is my post body'
            },
            'relationships': {
              'author': {
                'data': { 'type': 'person', 'id': 'John' }
              },
              'comments': {
                'data': [
                  { 'type': 'comments', 'id': '5' },
                  { 'type': 'comments', 'id': '12' }
                ]
              }
            }
          }
        }

        post_params = described_class.deserialize(
          post_json,
          ARModels::PostDeserializer,
          post,
          author: { id_param: :name, resource_collection: ARModels::Author.where(code: 'foo') }
        )
        expect(post_params).to eq(
          title: 'Rails is Omakase',
          body: 'This is my post body',
          author_id: 9,
          comment_ids: [5, 12]
        )
      end
    end
  end

  describe '.find_resource' do
    context 'with a resource matching the document' do
      let!(:resource) { ARModels::Author.create(id: 42) }
      let(:document) { { data: { id: '42', type: 'person' } } }

      it 'returns the matching resource' do
        actual = described_class.find_resource(document, ARModels::AuthorDeserializer)
        expect(actual).to eq(resource)
      end
    end

    context 'with a resource_collection argument' do
      let!(:resource_a) { ARModels::Author.create(id: 42, name: 'Jack', code: 'foo') }
      let!(:resource_b) { ARModels::Author.create(id: 43, name: 'John', code: 'foo') }
      let(:document) { { data: { id: 'foo', type: 'person' } } }

      it 'returns the resource scoped to the resource_collection' do
        actual = described_class.find_resource(
          document,
          ARModels::AuthorDeserializer,
          id_param: 'code',
          resource_collection: ARModels::Author.where(name: 'Jack')
        )
        expect(actual).to eq(resource_a)
      end
    end
  end

  describe '.find_collection' do
    context 'with resources matching the document' do
      let!(:resource_a) { ARModels::Author.create(id: 42) }
      let!(:resource_b) { ARModels::Author.create(id: 43) }
      let(:document) { { data: [{ id: '42', type: 'person' }, { id: '43', type: 'person' }] } }

      it 'returns all matching resources' do
        actual = described_class.find_collection(document, ARModels::AuthorDeserializer)
        expect(actual).to eq([resource_a, resource_b])
      end
    end

    context 'with a resource_collection argument' do
      let!(:resource_a) { ARModels::Author.create(id: 42, name: 'Jack', code: 'foo') }
      let!(:resource_b) { ARModels::Author.create(id: 43, name: 'John', code: 'foo') }
      let!(:resource_c) { ARModels::Author.create(id: 44, name: 'Jack', code: 'bar') }
      let(:document) { { data: [{ id: 'foo', type: 'person' }, { id: 'bar', type: 'person' }] } }

      it 'returns the resource scoped to the resource_collection' do
        actual = described_class.find_collection(
          document,
          ARModels::AuthorDeserializer,
          id_param: 'code',
          resource_collection: ARModels::Author.where(name: 'Jack')
        )
        expect(actual).to eq([resource_a, resource_c])
      end
    end

    context 'with an empty array' do
      let(:document) { { data: [] } }

      it 'returns an empty array' do
        actual = described_class.find_collection(document, ARModels::AuthorDeserializer)
        expect(actual).to eq([])
      end
    end
  end
end
