# FunWithJsonApi
[![Build Status](https://travis-ci.org/bmorrall/fun_with_json_api.svg?branch=master)](https://travis-ci.org/bmorrall/fun_with_json_api)

## Deserializer

With a User Deserializer:

```
class UserDeserializer < FunWithJsonApi::Deserializer
  type 'people'
  resource_class User
end
```

and a Article Deserializer:

```
class ArticlesDeserializer
  resource_class Article

  attribute :title

  has_one :author, -> { UserDeserializer }
end
```

Calling `FunWithJsonApi.deserialize(params, ArticlesDeserializer)` within a controller,
will convert:

```
{
  "type": "articles",
  "attributes": {
    "title": "Rails is Omakase"
  },
  "relationships": {
    "author": {
      "data": { "type": "people", "id": "9" }
    }
  }
}
```

Into parameters than can create/update a `Article`:

```
{
  title: "Rails is Omakase",
  author_id: 9
}
```

With a sprinking of json_api validation, and a lot of semantically correct json api error responses.

### Attribute Types

| Attribute Type      | Format      | Ruby Object        | Example                       |
| ------------------- | ----------- | -------------      | ----------------------------- |
| string              | :string     | String             | 'Lorem ipsum dolor sit amet.. |
| text                | :string     | String             | 'Lorem ipsum dolor sit amet.. |
| boolean             | :boolean    | Boolean.TRUE/FALSE | true, false                   |
| date                | :date       | Date               | '2016-03-12'                  |
| datetime (ISO 8601) | :datetime   | DateTime           | '2016-03-12T16:33:17+11:00'   |
| decimal             | :decimal    | BigDecimal         | 123.45                        |
| float               | :float      | Float              | 12.34                         |
| integer             | :integer    | Integer            | 12                            |

## Exceptions

FunWithJsonApi includes a `render_fun_with_json_api_exception` helper method,
this generally includes an expanded payload with additional debugging information,
while protecting the API from revealing its internal workings.

You can handle most json api exceptions with the following code:

```
class ApplicationController < ActionController::Base
  include FunWithJsonApi::ControllerMethods

  rescue_from FunWithJsonApi::Exception, with: :render_fun_with_json_api_exception
end
```

## License

This project rocks and uses MIT-LICENSE.
