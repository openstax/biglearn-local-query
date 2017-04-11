require 'rails_helper'

RSpec.describe OpenStax::Biglearn::Scheduler, type: :external do
  context 'configuration' do
    it 'can be configured' do
      configuration = OpenStax::Biglearn::Scheduler.configuration
      expect(configuration).to be_a(OpenStax::Biglearn::Scheduler::Configuration)

      OpenStax::Biglearn::Scheduler.configure do |config|
        expect(config).to eq configuration
      end
    end
  end

  context 'scheduler api calls' do
    [].each do |method, requests_proc, result_class|
      it "delegates #{method} to the client implementation and returns the response" do
        requests = requests_proc.nil? ? nil : instance_exec(&requests_proc)

        expect(OpenStax::Biglearn::Scheduler.client).to receive(method).and_call_original

        results = requests.nil? ? OpenStax::Biglearn::Scheduler.send(method) :
                                  OpenStax::Biglearn::Scheduler.send(method, requests)

        results = results.values if requests.is_a?(Array) && results.is_a?(Hash)

        [results].flatten.each { |result| expect(result).to be_a result_class }
      end
    end
  end
end
