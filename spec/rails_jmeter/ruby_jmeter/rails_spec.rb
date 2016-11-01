require "spec_helper"

class RailsModel
  include RailsJmeter::RubyJmeter::Rails
end

describe RailsJmeter::RubyJmeter::Rails do
  let(:instance) { RailsModel.new }
  let(:block) { ->() {} }
  let(:request) do
    instance_double(
      "Request",
      name: "name",
      method_name: :get,
      request_params: { mock: :me },
      filtered_response: :response
    )
  end

  describe "#rails_request" do
    subject { instance.rails_request :arg1, {}, &block }

    it "creates a new rails request" do
      expect(RailsJmeter::Rails::Request).to receive(:new).and_wrap_original do |m, *args, &_block|
        expect(args).to eql [:arg1, {}]
        expect(_block).to eql block
        m.call(*args, &_block)
      end
      subject
    end

    it "the context is set" do
      expect(subject.context).to eql instance
    end

    it "#r does the same thing" do
      expect(instance.method(:rails_request)).to eql instance.method(:r)
    end
  end

  describe "#r_request" do
    let(:jmeter_options) { { some_option: "1" } }
    subject { instance.r_request request, jmeter_options, :arg, &block }

    it "calls the request method with the right params" do
      expect(request).to receive(:request_params).with(body: true)
      expect(instance).to receive(:get).with({ name: "name", some_option: "1", mock: :me }, :arg) do |*args, &_block|
        expect(_block).to eql block
      end
      subject
    end

    context "with :raw_body given" do
      let(:jmeter_options) { { raw_body: "{}" } }

      it "calls request_params with no body" do
        expect(request).to receive(:request_params).with(body: false)
        expect(instance).to receive(:get)
        subject
      end
    end
  end

  describe "#r_request_and_assert" do
    subject { instance.r_request_and_assert request, { some_option: "1" }, :arg, &block }
    let(:dsl) { RailsModel.new } # can't use test double due to complex mocking

    it "calls #r_request" do
      expect(instance).to receive(:r_request).with(request, { some_option: "1" }, :arg) do |*args, &_block|
        exec_count = 0
        expect(dsl).to receive(:instance_exec).twice.and_wrap_original do |m, &exec_block|
          expect(exec_block).to eql [_block, block][exec_count]
          exec_count += 1
          m.call(&exec_block)
        end
        expect(dsl).to receive(:assert_response).with(:response, array_limit: 10)
        dsl.instance_exec(&_block)
      end
      subject
    end

    describe "#assert_response" do
      let(:response_object) { { here: %w[with array], again: "", with: [{more: 10}] } }
      subject { instance.assert_response response_object }

      it "calls the right assert" do
        expect(instance).to receive(:assert).with(json: ".here[0]", value: "with", name: ".here[0] == \"with\"").ordered
        expect(instance).to receive(:assert).with(json: ".here[1]", value: "array", name: ".here[1] == \"array\"").ordered
        expect(instance).to receive(:assert).with(json: ".again", value: "", name: ".again == \"\"").ordered
        expect(instance).to receive(:assert).with(json: ".with[0].more", value: 10, name: ".with[0].more == 10").ordered
        subject
      end
    end
  end
end