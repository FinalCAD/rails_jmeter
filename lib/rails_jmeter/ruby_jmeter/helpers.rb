module RailsJmeter
  module RubyJmeter
    module Helpers
      def get_property(property_name)
        "${__property(#{property_name})}"
      end
      alias_method :p, :get_property

      def set_property(property_name, json_path)
        extract name: property_name, json: json_path
        # because threads can't share variables, we move them to properties
        # https://www.blazemeter.com/blog/knit-one-pearl-two-how-use-variables-different-thread-groups
        beanshell_assertion query: "${__setProperty(#{property_name}, ${#{property_name}})};"
      end
    end
  end
end

RubyJmeter::ExtendedDSL.send(:include, RailsJmeter::RubyJmeter::Helpers)