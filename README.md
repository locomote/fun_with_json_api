# FunWithJsonApi

## Deserializer


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
