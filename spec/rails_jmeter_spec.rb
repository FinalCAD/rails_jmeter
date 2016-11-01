require "spec_helper"

describe RailsJmeter do
  it "has a version number" do
    expect(RailsJmeter::VERSION).not_to be nil
  end

  describe "::load_jmeter_files" do
    subject { described_class.load_jmeter_files }
    around {|example| Dir.chdir("spec/fixtures", &example) }

    it "loads all the jmeter files in the jmeter directory" do
      expect(described_class).to receive(:load).with("jmeter/folder_test/folder_test_jmeter.rb")
      expect(described_class).to receive(:load).with("jmeter/general_test_jmeter.rb")
      subject
    end
  end

  describe "::test_suite" do
    subject { described_class.test_suite }

    it "returns a test suite" do
      expect(subject.class).to eql RailsJmeter::TestSuite
    end
  end
end
