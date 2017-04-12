require 'rails_helper'

RSpec.describe Services::CalculateClues::Service, type: :service do
  let(:service) { described_class.new }

  let(:action)  { service.process }

  context "when no clue_calculations are given by the scheduler" do
    it "sends an empty array of clue_calculation_updates to the scheduler" do
      expect(OpenStax::Biglearn::Scheduler).to(
        receive(:fetch_clue_calculations)
      ).and_return(clue_calculations: [])
      expect(OpenStax::Biglearn::Scheduler).to receive(:update_clue_calculations).with([])

      action
    end
  end

  context "when some clue_calculations are given by the scheduler" do
    let(:calculation_uuid_1)              { SecureRandom.uuid }
    let(:ecosystem_uuid_1)                { SecureRandom.uuid }
    let(:num_student_uuids_1)             { rand(10) + 1 }
    let(:num_exercise_uuids_1)            { rand(10) + 1 }
    let(:num_responses_1)                 { rand(10) + 1 }
    let(:responses_1)                     do
      num_responses_1.times.map do
        {
          response_uuid: SecureRandom.uuid,
          trial_uuid: SecureRandom.uuid,
          is_correct: [true, false].sample
        }
      end
    end

    let(:calculation_uuid_2)              { SecureRandom.uuid }
    let(:ecosystem_uuid_2)                { SecureRandom.uuid }
    let(:num_student_uuids_2)             { rand(10) + 1 }
    let(:num_exercise_uuids_2)            { rand(10) + 1 }
    let(:num_responses_2)                 { rand(10) + 1 }
    let(:responses_2)                     do
      num_responses_2.times.map do
        {
          response_uuid: SecureRandom.uuid,
          trial_uuid: SecureRandom.uuid,
          is_correct: [true, false].sample
        }
      end
    end

    let(:clue_calculations)               do
      [
        {
          calculation_uuid: calculation_uuid_1,
          ecosystem_uuid: ecosystem_uuid_1,
          student_uuids: num_student_uuids_1.times.map { SecureRandom.uuid },
          exercise_uuids: num_exercise_uuids_1.times.map { SecureRandom.uuid },
          responses: responses_1
        },
        {
          calculation_uuid: calculation_uuid_2,
          ecosystem_uuid: ecosystem_uuid_2,
          student_uuids: num_student_uuids_2.times.map { SecureRandom.uuid },
          exercise_uuids: num_exercise_uuids_2.times.map { SecureRandom.uuid },
          responses: responses_2
        }
      ]
    end

    let(:expected_clue_data_by_calc_uuid) do
      expected_clue_1 = Services::CalculateClues::Service.send(
        :calculate_clue, responses_1, ecosystem_uuid_1
      )
      expected_clue_2 = Services::CalculateClues::Service.send(
        :calculate_clue, responses_2, ecosystem_uuid_2
      )

      {
        calculation_uuid_1 => expected_clue_1,
        calculation_uuid_2 => expected_clue_2
      }
    end

    it "sends a clue_calculation_update for each given clue_calculation to the scheduler" do
      expect(OpenStax::Biglearn::Scheduler).to(
        receive(:fetch_clue_calculations)
      ).and_return(clue_calculations: clue_calculations)
      expect(OpenStax::Biglearn::Scheduler).to receive(:update_clue_calculations) do |updates|
        updates.each do |update|
          expected_clue_data = expected_clue_data_by_calc_uuid.fetch update[:calculation_uuid]
          expect(update[:algorithm_name]).to be_nil
          expect(update[:clue_data]).to eq expected_clue_data
        end
      end

      action
    end
  end
end
