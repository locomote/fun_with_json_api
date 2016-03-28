require 'spec_helper'

# rubocop:disable all
describe 'Example' do
  xit 'prints out the thing' do
    params = {
      id: 'zorglub',
      title: 'Ember Hamster',
      published_at: '2016-03-12',
      enabled_at: '2016-03-12T17:19:28+11:00',
      promoted: false,
      times_read: '414',
      author_id: nil,
      editor_id: '9',
      comment_ids: %w(1 2)
    }

    puts "attributes: #{ArticleDeserializer.attributes.map(&:name).inspect}"

    deserializer = ArticleDeserializer.create
    deserialized_params = deserializer.sanitize_params(params)
    puts "title: #{deserialized_params[:title].inspect}"
    puts "published_at: #{deserialized_params[:published_at].inspect}"
    puts "enabled_at: #{deserialized_params[:enabled_at].inspect}"
    puts "times_read: #{deserialized_params[:times_read].inspect}"
    puts deserialized_params.inspect

    expect(deserializer.type).to eq 'articles'
    expect(deserializer.resource_class).to eq Article
  end

  xit 'deserializes params' do
    document_data = {
      # id: 'zorglub',
      type: 'articles',
      attributes: {
        title: 'Ember Hamster',
        date: '2016-03-12',
        enabled_at: '2016-03-12T13:45:40+09:30',
        promoted: false,
        times_read: '414'
      },
      relationships: {
        author: { data: nil },
        editor: { data: { id: 'demouser', type: 'persons' } },
        comments: { data: [{ id: '1', type: 'comments' }, { id: '2', type: 'comments' }] }
      }
    }
    document = { data: document_data }.as_json

    document_params = FunWithJsonApi.deserialize(document, ArticleDeserializer)
    expect(document_params).to eq(
      # id: Article.find(code: 'zorglub').id,
      title: 'Ember Hamster',
      published_at: Date.new(2016, 03, 12),
      enabled_at: DateTime.new(2016, 03, 12, 4, 15, 40, 0),
      promoted: false,
      times_read: 414,
      author_id: nil,
      editor_id: Person.find_by!(username: 'demouser').id,
      comment_ids: [1, 2]
    )
    puts "deserialized: #{document_params.inspect}"
  end
end
# rubocop:enable all
