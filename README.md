# RailsJmeter

Rails scaffolding for your [ruby-jmeter](https://github.com/flood-io/ruby-jmeter) tests---gem is in development.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails_jmeter'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rails_jmeter

## Usage

Add the following files:

```ruby
# Rails.root/jmeter/jmeter_helper.rb
ENV['RAILS_ENV'] = 'test'

require ::File.expand_path('../../config/environment',  __FILE__)

RailsJmeter.base do
  # base top-level code using ruby-jmeter syntax
  
  view_results_tree # this line will slow large load tests, but it's here to show you what's happening
end
```

```ruby
# Rails.root/jmeter/projects_controller_jmeter.rb
require './jmeter/jmeter_helper'

RailsJmeter.unit_test do
  get url: 'http://localhost:3000' # ruby-jmeter syntax
end

# which is the same as:
RailsJmeter.embed do
  threads 1, loops: 1 do
    get url: 'http://localhost:3000' 
  end
end
```

Run the `rails_jmeter <OPTIONAL_FILE_PATH>` executable to open up the tests in `jmeter`.

## General Helpers
`get_property` and `set_property` are basic helpers to access properties---as opposed to variables. Properties are useful because they can be shared across threads.

Sharing properties in the `jmeter_helper.rb` is useful:

```ruby
# Rails.root/jmeter/jmeter_helper.rb

# ... same code as above

RailsJmeter.base do
  get url: 'http://localhost:3000/projects' do
    set_property :first_project_id, ".projects[0].id" # this String is a JSONPath
  end
end
```

and you can use the property as thus:

```ruby
# Rails.root/jmeter/projects_controller_jmeter.rb
require './jmeter/jmeter_helper'

RailsJmeter.unit_test do
  get url: "http://localhost:3000/projects/#{get_property(:first_project_id)}"
end
```


## Rails Helpers

### r_request
`r_request` is a helper for writing tests for rails routes. It defaults to `http://localhost:3000` and
`DOMAIN`, `PORT`, and `PROTOCOL` can be set as `ENV` variables.

```ruby
rails_request = r(:get, :project, id: 1, format: :json)
ruby_jmeter_options = {}
r_request rails_request, ruby_jmeter_options do
  assert json: ".here[0]", value: "with"
end

# is the same as
get ruby_jmeter_options.reverse_merge(url: "http://localhost:3000/projects/1.json", name: "project_GET") do
  assert json: ".here[0]", value: "with"
end
```

For `PUT` and `POST` requests, you can specify the `raw_body` manually:
                               
```ruby
ruby_jmeter_options = { raw_body: { name: "my project name" }.to_json }
``` 

A shorthand is specifying the request body in a `.json` file:
```json
// in Rails.root/jmeter/requests/projects_controller/projects_POST_request.json
{ "name": "my project name" } 
```
 
 You can filter the `.json` file request body by passing it to the `rails_request`:
```ruby
 rails_request = r(:get, :project, id: 1, format: :json) do |hash|
  hash.each do |key, value|
    hash[key] = SOME_REAL_ID if key == "id"  
  end
 end
```

You can also set a default filter via:
```ruby
RailsJmeter::Rails::Request.default_request_filter = ->(hash) {  }
```

### r_request_and_assert

`r_request_and_assert` calls `r_request` and does assertions on the responses based on a `.json` file:
```json
// in Rails.root/jmeter/requests/projects_controller/project_GET_response.json
{ "here": ["with", "array"], "again": "", "with": [{"more": 10}] }
```

```ruby
r_request_and_assert rails_request, ruby_jmeter_options

# is the same as:
r_request rails_request, ruby_jmeter_options do
  assert json: ".here[0]", value: "with", name: ".here[0] == \"with\""
  assert json: ".here[1]", value: "array", name: ".here[1] == \"array\""
  assert json: ".again", value: "", name: ".again == \"\""
  assert json: ".with[0].more", value: 10, name: ".with[0].more == 10"
end
```

You can filter the `.json` file expected response manually:
```ruby
r_request rails_request, ruby_jmeter_options do
  response_hash = rails_request.filtered_respose do |hash|
    hash.reject! { |key, value| key == "id" }
  end
  assert_response response_hash
end
```

You can also set a default filter via:
```ruby
RailsJmeter::Rails::Request.default_response_filter = ->(hash) {  }
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

