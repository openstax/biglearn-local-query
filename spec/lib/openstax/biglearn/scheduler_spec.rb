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
    calculation_1_uuid = SecureRandom.uuid
    calculation_2_uuid = SecureRandom.uuid

    random_sorted_numbers_1 = 3.times.map { rand }.sort
    clue_data_1 = {
      minimum: random_sorted_numbers_1.first,
      most_likely: random_sorted_numbers_1.second,
      maximum: random_sorted_numbers_1.third,
      ecosystem_uuid: SecureRandom.uuid,
      is_real: [true, false].sample
    }
    random_sorted_numbers_2 = 3.times.map { rand }.sort
    clue_data_2 = {
      minimum: random_sorted_numbers_2.first,
      most_likely: random_sorted_numbers_2.second,
      maximum: random_sorted_numbers_2.third,
      ecosystem_uuid: SecureRandom.uuid,
      is_real: [true, false].sample
    }

    exercise_uuids_1 = rand(10).times.map { SecureRandom.uuid }
    exercise_uuids_2 = rand(10).times.map { SecureRandom.uuid }

    [
      [
        :fetch_clue_calculations,
        nil,
        Hash
      ],
      [
        :fetch_exercise_calculations,
        nil,
        Hash
      ],
      [
        :update_clue_calculations,
        [
          {
            calculation_uuid: calculation_1_uuid,
            clue_data: clue_data_1
          },
          {
            calculation_uuid: calculation_2_uuid,
            clue_data: clue_data_2
          }
        ],
        Hash
      ],
      [
        :update_exercise_calculations,
        [
          {
            calculation_uuid: calculation_1_uuid,
            exercise_uuids: exercise_uuids_1
          },
          {
            calculation_uuid: calculation_2_uuid,
            exercise_uuids: exercise_uuids_2
          }
        ],
        Hash
      ]
    ].each do |method, requests, result_class|
      it "delegates #{method} to the client implementation and returns the response" do
        expect(OpenStax::Biglearn::Scheduler.client).to receive(method).and_call_original

        results = requests.nil? ? OpenStax::Biglearn::Scheduler.send(method) :
                                  OpenStax::Biglearn::Scheduler.send(method, requests)

        results = results.values if requests.is_a?(Array) && results.is_a?(Hash)

        [results].flatten.each { |result| expect(result).to be_a result_class }
      end
    end
  end
end
