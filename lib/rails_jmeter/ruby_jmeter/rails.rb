require 'rails_jmeter/rails/request'

module RailsJmeter
  module RubyJmeter
    module Rails
      def rails_request(*args, &block)
        request = RailsJmeter::Rails::Request.new(*args, &block)
        request.context = self
        request
      end
      alias_method :r, :rails_request

      def r_request(request, ruby_jmeter_options={}, *args, &block)
        ruby_jmeter_options = ruby_jmeter_options.symbolize_keys
        ruby_jmeter_options = ruby_jmeter_options.reverse_merge!(name: request.name)
        ruby_jmeter_options.reverse_merge!(request.request_params(body: !ruby_jmeter_options[:raw_body]))
        public_send(request.method_name, ruby_jmeter_options, *args, &block)
      end

      def r_request_and_assert(request, *args, &block)
        r_request(request, *args) do
          instance_exec(&block) if block
          assert_response request.filtered_response, array_limit: 10 # set limit for lag reasons
        end
      end

      # Given a Hash or Array, it calls assert statements that matches the structure
      def assert_response(item, json_path: "", array_limit: nil)
        if item.class == Array
          item = item.take(array_limit) if array_limit
          item.each.with_index do |element, index|
            assert_response element, json_path: json_path + "[#{index}]", array_limit: array_limit
          end
        elsif item.class == Hash
          item.each do |key, value|
            assert_response value, json_path: json_path + ".#{key}", array_limit: array_limit
          end
        else
          item = item.nil? ? "null" : item
          assert json: json_path, value: item, name: "#{json_path} == #{item.to_json}"
        end
      end
    end
  end
end
RubyJmeter::ExtendedDSL.send(:include, RailsJmeter::RubyJmeter::Rails)