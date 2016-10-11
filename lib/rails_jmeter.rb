require "rails_jmeter/version"

require 'rails_jmeter/test_suite'

module RailsJmeter
  class << self
    def test_suite
      @test_suite ||= TestSuite.new
    end

    %i[
      embed
      unit_test
      base
      ].each do |method_name|
      define_method(method_name) {|*args, &block| test_suite.public_send(method_name, *args, &block) }
    end
  end
end