require "spec_helper"

describe RailsJmeter::TestSuite do
  let(:instance) { described_class.new }

  describe "#embed" do
    subject { instance.embed {|test_arg| } }

    it "adds a new block to embed_procs" do
      expect(instance.embed_procs).to eql []
      subject
      expect(instance.embed_procs.map(&:parameters)).to eql [[[:opt, :test_arg]]]
    end
  end

  describe "#unit_test" do
    subject { instance.unit_test {|test_arg| } }

    it "adds a new block to unit_test_procs" do
      expect(instance.unit_test_procs).to eql []
      subject
      expect(instance.unit_test_procs.map(&:parameters)).to eql [[[:opt, :test_arg]]]
    end
  end

  describe "#base" do
    subject { instance.base {|test_arg| } }

    it "sets the base proc" do
      expect { subject }.to change { instance.base_proc.parameters }.
        from([]).
        to([[:opt, :test_arg]])
    end
  end

  describe "#run" do
    subject { instance.run("test") }

    it "sets up and runs" do
      expect(instance.dsl).to receive(:run).with("test")
      subject
    end
  end

  describe "#setup" do
    it "runs once and setups up as true" do
      expect(instance).to receive(:add_base_proc).once
      expect(instance).to receive(:add_embed_procs).once
      expect(instance).to receive(:add_unit_test_procs).once

      instance.send(:setup)
      expect(instance.setup?).to eql true
      instance.send(:setup)
    end
  end

  describe "#dsl" do
    subject { instance.dsl("test") }

    it "returns the dsl" do
      expect(RubyJmeter::ExtendedDSL).to receive(:new).with("test").and_return "waka"
      expect(instance).to receive(:setup).once
      expect(subject).to eql "waka"
      instance.dsl
    end
  end

  context "add_proc methods" do
    let(:proc) { -> {} }
    let(:dsl) { RubyJmeter::ExtendedDSL.new({}) }
    before { allow(instance).to receive(:dsl).and_return(dsl) }

    describe "#add_base_proc" do
      before { instance.base(&proc) }
      subject { instance.send(:add_base_proc) }

      it "evals the dsl with the base_proc" do
        expect(dsl).to receive(:instance_exec) {|&block| expect(block).to eql(proc) }
        subject
      end
    end

    describe "#add_embed_procs" do
      before { instance.embed(&proc) }
      subject { instance.send(:add_embed_procs) }

      it "evals the dsl with the base_proc" do
        expect(dsl).to receive(:instance_exec) {|&block| expect(block).to eql(proc) }
        subject
      end
    end

    describe "#add_unit_test_procs" do
      let(:proc) { -> { Kernel.puts "add_unit_test_procs" } }
      before { instance.unit_test(&proc) }

      subject { instance.send(:add_unit_test_procs) }

      it "evals the dsl with the base_proc" do
        expect(Kernel).to receive(:puts).with("add_unit_test_procs")
        subject
      end
    end
  end
end