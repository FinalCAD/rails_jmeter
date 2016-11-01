module RailsJmeter
  class TestSuite
    require 'ruby-jmeter' # this defines a method in the global namespace, which I want to avoid

    attr_reader :embed_procs
    attr_reader :unit_test_procs
    attr_reader :base_proc

    def initialize
      @embed_procs = []
      @unit_test_procs = []
      @base_proc = -> {}
    end

    def embed(&block)
      embed_procs << block
    end

    def unit_test(&block)
      unit_test_procs << block
    end

    def base(&block)
      @base_proc = block
    end

    def run(*args)
      dsl.run *args
    end

    def setup?
      !!@setup
    end

    def dsl(params={})
      return @dsl if @dsl
      @dsl ||= RubyJmeter::ExtendedDSL.new(params)
      setup
      return @dsl
    end

    protected

    def setup
      return if setup?
      @setup = true

      add_base_proc
      add_embed_procs
      add_unit_test_procs
    end

    def add_base_proc
      dsl.instance_exec &base_proc
    end

    def add_embed_procs
      embed_procs.each do |proc|
        dsl.instance_exec &proc
      end
    end

    def add_unit_test_procs
      unit_test_procs = self.unit_test_procs
      dsl.threads 1, loops: 1 do
        unit_test_procs.each { |proc| instance_exec(&proc) }
      end
    end
  end
end