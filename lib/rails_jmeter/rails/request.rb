module RailsJmeter
  module Rails
    class Request
      attr_reader :method_name, :route_name, :route_options, :request_body_filter
      attr_accessor :context

      def initialize(method_name, route_name, route_options={}, &block)
        @method_name = method_name
        @route_name = route_name
        @route_options = route_options
        @request_body_filter = block || self.class.default_request_filter
      end

      def name
        "#{route_name}_#{method_name.to_s.upcase}"
      end

      REQUEST_BODY_METHOD_NAMES = %i[post put].freeze

      def request_params(body: true)
        request_params = url_params
        if body && REQUEST_BODY_METHOD_NAMES.include?(method_name)
          request_params.reverse_merge!(
            raw_body: filtered_request_body.to_json
          )
        end
        request_params
      end

      def url_params
        domain = ENV['DOMAIN'] || "localhost"
        is_localhost = domain == "localhost"
        {
          domain: domain,
          port: ENV['PORT'] || (is_localhost ? "3000" : nil),
          protocol: ENV['PROTOCOL'] || (is_localhost ? "http" : "https"),
          path: path,
          url: ""
        }
      end

      def path
        path = url_helpers.public_send("#{route_name}_path", route_options)
        URI.unescape(path) # so variable names are possible
      end

      def filtered_request_body
        filter_json request_body, &request_body_filter
      end

      # JSON request body as Ruby Object
      def request_body
        inferred_json "/#{route_name}_#{method_name.to_s.upcase}_request.json"
      end

      def filtered_response(&block)
        filter_json expected_response, &(block || self.class.default_response_filter)
      end

      # Finds the expected JSON response as Ruby Object
      def expected_response
        inferred_json "/#{route_name}_#{method_name.to_s.upcase}_response.json"
      end

      protected
      def url_helpers
        @url_helpers ||= ::Rails.application.routes.url_helpers
      end

      TEST_FILE_SUFFIX = "_jmeter.rb".freeze

      def inferred_json(replace_jmeter_suffix)
        call_stack = caller[1..15].find { |call_stack| call_stack.index TEST_FILE_SUFFIX }
        test_file_name = call_stack[0..call_stack.index(":") - 1]
                           .sub("jmeter/", "jmeter/requests/")

        json_file_name = test_file_name.sub("_jmeter.rb", replace_jmeter_suffix)
        JSON.parse(File.read(json_file_name))
      rescue Errno::ENOENT
        puts "File not found - #{json_file_name}"
        {}
      end

      # takes an array_or_hash (from a JSON file) and filters it based on the &block = ->(hash) { }
      #
      # designed to change values that vary throughout tests (ids, timestamps, etc.)
      #
      # &block must be an destructive operation (changes the passed hash)
      def filter_json(array_or_hash, &block)
        if array_or_hash.class == Array
          array_or_hash.each { |item| filter_json(item, &block) }
        elsif array_or_hash.class == Hash
          context ? context.instance_exec(array_or_hash, &block) : block.call(array_or_hash)
          array_or_hash.each {|k, v| filter_json(v, &block) }
        end
        array_or_hash
      end

      class << self
        attr_writer :default_request_filter, :default_response_filter

        def default_request_filter
          @default_request_filter || ->(hash) {}
        end

        def default_response_filter
          @default_response_filter || ->(hash) {}
        end
      end
    end
  end
end
