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

  random_sorted_numbers_1 = 3.times.map { rand }.sort
  clue_data_1 = {
    minimum: random_sorted_numbers_1.first,
    most_likely: random_sorted_numbers_1.second,
    maximum: random_sorted_numbers_1.third,
    is_real: [true, false].sample,
    ecosystem_uuid: SecureRandom.uuid
  }
  random_sorted_numbers_2 = 3.times.map { rand }.sort
  clue_data_2 = {
    minimum: random_sorted_numbers_2.first,
    most_likely: random_sorted_numbers_2.second,
    maximum: random_sorted_numbers_2.third,
    is_real: [true, false].sample,
    ecosystem_uuid: SecureRandom.uuid
  }

  exercise_uuids_1 = rand(10).times.map { SecureRandom.uuid }
  exercise_uuids_2 = rand(10).times.map { SecureRandom.uuid }

  when_tagged_with_vcr = { vcr: ->(v) { !!v } }

  before(:all, when_tagged_with_vcr) do
    VCR.configure do |config|
      config.define_cassette_placeholder('<CLUE DATA 1>'     ) { clue_data_1      }
      config.define_cassette_placeholder('<CLUE DATA 2>'     ) { clue_data_2      }
      config.define_cassette_placeholder('<EXERCISE UUIDS 1>') { exercise_uuids_1 }
      config.define_cassette_placeholder('<EXERCISE UUIDS 2>') { exercise_uuids_2 }
    end
  end

  [
    [
      :fetch_clue_calculations,
      { algorithm_name: OpenStax::Biglearn::Scheduler::DEFAULT_ALGORITHM_NAME },
      { clue_calculations: [] }
    ],
    [
      :fetch_exercise_calculations,
      { algorithm_name: OpenStax::Biglearn::Scheduler::DEFAULT_ALGORITHM_NAME },
      { exercise_calculations: [] }
    ],
    [
      :update_clue_calculations,
      [
        {
          algorithm_name: OpenStax::Biglearn::Scheduler::DEFAULT_ALGORITHM_NAME,
          clue_data: clue_data_1
        },
        {
          algorithm_name: OpenStax::Biglearn::Scheduler::DEFAULT_ALGORITHM_NAME,
          clue_data: clue_data_2
        }
      ],
      [
        {
          calculation_status: 'calculation_accepted'
        },
        {
          calculation_status: 'calculation_accepted'
        }
      ]
    ],
    [
      :update_exercise_calculations,
      [
        {
          algorithm_name: OpenStax::Biglearn::Scheduler::DEFAULT_ALGORITHM_NAME,
          exercise_uuids: exercise_uuids_1
        },
        {
          algorithm_name: OpenStax::Biglearn::Scheduler::DEFAULT_ALGORITHM_NAME,
          exercise_uuids: exercise_uuids_2
        }
      ],
      [
        {
          calculation_status: 'calculation_accepted'
        },
        {
          calculation_status: 'calculation_accepted'
        }
      ]
    ]
  ].group_by(&:first).each do |method, examples|
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
