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
# Rails.root/controllers/google_controller_jmeter.rb
require './jmeter/jmeter_helper'

RailsJmeter.unit_test do
  get url: 'https://google.com' # ruby-jmeter syntax
end

# which is the same as:
# RailsJmeter.embed do
#   threads 1, loops: 1 do
#     get url: 'https://google.com' 
#   end
# end
```

Run the `rails_jmeter <OPTIONAL_FILE_PATH>` executable to open up the tests in `jmeter`. Will add more features later.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

