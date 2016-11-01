require "spec_helper"

class HelperModel
  include RailsJmeter::RubyJmeter::Helpers
end

describe RailsJmeter::RubyJmeter::Helpers do
  let(:instance) { HelperModel.new }

  describe "#get_property" do
    subject { instance.get_property("hello") }

    it "returns the correct string" do
      expect(subject).to eql "${__property(hello)}"
    end

    it "is the same as #p" do
      expect(instance.method(:get_property)).to eql instance.method(:p)
    end
  end

  describe "set_property" do
    subject { instance.set_property("name", "some_path") }

    it "calls the right methods" do
      expect(instance).to receive(:extract).with(name: "name", json: "some_path")
      expect(instance).to receive(:beanshell_assertion).with(query: "${__setProperty(name, ${name})};")
      subject
    end
  end
end