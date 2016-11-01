require "rails_jmeter/version"

require 'active_support/core_ext/hash'

require 'rails_jmeter/test_suite'
require 'rails_jmeter/ruby_jmeter/helpers'

require 'rails_jmeter/ruby_jmeter/rails'

module RailsJmeter
  class << self
    def load_jmeter_files
      Dir[File.join('jmeter/**/*_jmeter.rb')].each { |path| load path }
    end

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