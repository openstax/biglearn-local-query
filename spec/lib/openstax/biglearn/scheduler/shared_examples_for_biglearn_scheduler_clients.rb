require 'vcr_helper'

RSpec.shared_examples 'a biglearn scheduler client' do
  let(:configuration) { OpenStax::Biglearn::Scheduler.configuration }
  subject(:client)    { described_class.new(configuration) }

  let(:clue_matcher)  do
    {
      min: kind_of(Float),
      most_likely: kind_of(Float),
      max: kind_of(Float),
      is_real: included_in([true, false]),
      ecosystem_uuid: kind_of(String)
    }
  end

  random_sorted_numbers = 3.times.map { rand }.sort
  dummy_ecosystem_uuid = SecureRandom.uuid
  dummy_clue_data = {
    minimum: random_sorted_numbers.first,
    most_likely: random_sorted_numbers.second,
    maximum: random_sorted_numbers.third,
    is_real: [true, false].sample,
    ecosystem_uuid: dummy_ecosystem_uuid
  }

  dummy_exercise_uuids = rand(10).times.map { SecureRandom.uuid }

  when_tagged_with_vcr = { vcr: ->(v) { !!v } }

  before(:all, when_tagged_with_vcr) do
    VCR.configure do |config|
      config.define_cassette_placeholder('<EXERCISE UUIDS>'       ) { dummy_exercise_uuids }
    end
  end

  [].group_by(&:first).each do |method, examples|
    context "##{method}" do
      examples.each_with_index do |(method, requests, expected_responses, uuid_key), index|
        uuid_key ||= :calculation_uuid

        if requests.is_a?(Array)
          request_uuids = requests.map { SecureRandom.uuid }
          requests = requests.each_with_index.map do |request, request_index|
            request.merge(uuid_key => request_uuids[request_index])
          end

          before(:all, when_tagged_with_vcr) do
            VCR.configure do |config|
              requests.each_with_index do |request, request_index|
                config.define_cassette_placeholder(
                  "<#{method.to_s.upcase} EXAMPLE #{index+1} CALCULATION #{request_index+1} UUID>"
                ) { request_uuids[request_index] }
              end
            end
          end
        end

        it "returns the expected response for the #{(index + 1).ordinalize} set of requests" do
          expected_responses = instance_exec(&expected_responses) if expected_responses.is_a?(Proc)
          expected_responses = expected_responses.each_with_index.map do |expected_response, index|
            expected_response = instance_exec(&expected_response) if expected_response.is_a?(Proc)
            expected_response.merge(uuid_key => request_uuids[index])
          end if requests.is_a?(Array)

          actual_responses = requests.nil? ? client.send(method) : client.send(method, requests)

          expect([actual_responses].flatten).to match_array([expected_responses].flatten)
        end
      end
    end
  end
end
