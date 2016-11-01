require "spec_helper"

describe RailsJmeter::Rails::Request do
  let(:instance) { described_class.new(method_name, route_name, route_options, &block) }

  let(:method_name) { :get }
  let(:route_name) { :project }
  let(:route_options) { { id: 1 } }
  let(:block) { ->(hash) {} }

  let(:url_helpers) { double("UrlHelpers") }
  before do
    allow(instance).to receive(:url_helpers).and_return(url_helpers)
  end

  describe "#initialize" do
    subject { instance }

    let(:default_filter) { -> (the_test_filter) {} }
    around do |example|
      described_class.default_request_filter = default_filter
      example.run
      described_class.default_request_filter = nil
    end

    it "sets the #request_body_filter" do
      expect(instance.request_body_filter).to eql block
    end

    context "without block passed set" do
      let(:block) { nil }

      it "sets the #request_body_filter as the default filter" do
        expect(instance.request_body_filter).to eql default_filter
        expect(instance.request_body_filter.parameters).to eql [[:req, :the_test_filter]]
      end
    end
  end

  describe "#name" do
    subject { instance.name }
    it "gives a name" do
      expect(subject).to eql "project_GET"
    end
  end

  describe "#request_params" do
    let(:body) { true }

    subject { instance.request_params(body: body) }
    before do
      allow(instance).to receive(:url_params).and_return(some: :param)
      allow(instance).to receive(:filtered_request_body).and_return(body: :it)
    end

    it "returns the url params" do
      expect(subject).to eql(some: :param)
    end

    context "for POST" do
      let(:method_name) { :post }

      it "adds the body to the url params" do
        expect(subject).to eql(some: :param, raw_body: { body: :it }.to_json)
      end

      context "body=false" do
        let(:body) { false }

        it "it does not add the raw body" do
          expect(instance).to_not receive(:filtered_request_body)
          expect(subject).to eql(some: :param)
        end
      end
    end
  end

  describe "#url_params" do
    subject { instance.url_params }
    before do
      allow(instance).to receive(:path).and_return("some_path")
    end

    it "returns rails localhost settings" do
      expect(subject).to eql(domain: "localhost", port: "3000", protocol: "http", path: "some_path", url: "")
    end

    context "with custom environment" do
      before do
        stub_const('ENV', 'DOMAIN' => 'dom', 'PORT' => '5000', 'PROTOCOL' => 'ftp')
      end

      it "returns the defined settings" do
        expect(subject).to eql(domain: "dom", port: "5000", protocol: "ftp", path: "some_path", url: "")
      end
    end

    context "with changed domain" do
      before do
        stub_const('ENV', 'DOMAIN' => 'dom')
      end

      it "changes the default settings" do
        expect(subject).to eql(domain: "dom", port: nil, protocol: "https", path: "some_path", url: "")
      end
    end
  end

  describe "#path" do
    subject { instance.path }
    let(:projects_path) { URI.escape "/projects/1?${var}" }

    it "returns the unescaped path" do
      allow(url_helpers).to receive(:project_path).and_return(projects_path).with(id: 1)
      expect(subject).to eql "/projects/1?${var}"
    end
  end

  describe "#filtered_request_body" do
    subject { instance.filtered_request_body }

    before do
      allow(instance).to receive(:request_body).and_return(request: :body)
    end

    it "calls #filter_json" do
      expect(instance).to receive(:filter_json).with(request: :body) do |*args, &_block|
        expect(_block).to eql block
      end
      subject
    end
  end

  describe "#request_body" do
    subject { instance.request_body }

    it "calls #inferred_json" do
      expect(instance).to receive(:inferred_json).with("/project_GET_request.json")
      subject
    end
  end

  describe "#filtered_response" do
    let(:response_block) { ->() {} }
    subject { instance.filtered_response &response_block }

    before do
      allow(instance).to receive(:expected_response).and_return(response: :body)
    end

    let(:default_filter) { -> (the_test_filter) {} }
    around do |example|
      described_class.default_response_filter = default_filter
      example.run
      described_class.default_response_filter = nil
    end

    it "calls #filter_json" do
      expect(instance).to receive(:filter_json).with(response: :body) do |*args, &_block|
        expect(_block).to eql response_block
      end
      subject
    end

    context "with default block not passed" do
      let(:response_block) { nil }
      it "takes the default filter" do
        expect(instance).to receive(:filter_json) do |*args, &_block|
          expect(_block).to eql default_filter
          expect(_block.parameters).to eql [[:req, :the_test_filter]]
        end
        subject
      end
    end
  end

  describe "#expected_response" do
    subject { instance.expected_response }

    it "calls #inferred_json" do
      expect(instance).to receive(:inferred_json).with("/project_GET_response.json")
      subject
    end
  end

  describe "#inferred_json" do
    let(:replace_jmeter_suffix) { "/project_GET_request.json" }
    subject { instance.send :inferred_json, replace_jmeter_suffix }

    before do
      allow(instance).to receive(:caller).and_return(([''] * 10) + ["spec/fixtures/jmeter/projects_controller_jmeter.rb:20:in `unit_test'"])
    end

    it "finds the right json file and returns the right object" do
      expect(subject).to eql('in_json' => 'file')
    end

    context "with file not found" do
      let(:replace_jmeter_suffix) { "/not_found.json" }

      it "returns and emtpy hash" do
        expect(subject).to eql({})
      end
    end
  end

  describe '#filter_json' do
    subject { instance.send :filter_json, input, &filter }


    let(:input) { { name: "super", users: users } }
    let(:users) do
      [
        { id: 1, name: "mario" },
        { id: 2, name: "princess", friends: [{ id: 3, name: "toad" }] }
      ]
    end

    let(:filter) do
      -> (hash) { hash.reject! {|k, v| k == :id } }
    end
    let(:filtered_users) do
      [
        { name: "mario" },
        { name: "princess", friends: [{ name: "toad" }]}
      ]
    end

    it "filters the json recursively" do
      expect(subject).to eql(
                           name: "super",
                           users: filtered_users
                         )
    end

    context "with array input" do
      let(:input) { users }

      it "filters the array recursively" do
        expect(subject).to eql filtered_users
      end
    end
  end
end