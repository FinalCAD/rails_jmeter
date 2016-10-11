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
      jmeter.run *args
    end

    protected

    def jmeter
      unit_test_procs = self.unit_test_procs
      test do
        instance_eval(&base_proc)

        embed_procs.each { |proc| instance_eval(&proc) }

        threads 1, loops: 1 do
          unit_test_procs.each { |proc| instance_eval(&proc) }
        end
      end
    end
  end
end