require 'rails_helper'

RSpec.describe Services::CalculateExercises::Service, type: :service do
  let(:service) { described_class.new }

  let(:action)  { service.process }

  context "when no clue_calculations are given by the scheduler" do
    it "sends an empty array of clue_calculation_updates to the scheduler" do
      expect(OpenStax::Biglearn::Scheduler).to(
        receive(:fetch_exercise_calculations)
      ).and_return(exercise_calculations: [])
      expect(OpenStax::Biglearn::Scheduler).to receive(:update_exercise_calculations).with([])

      action
    end
  end

  context "when some clue_calculations are given by the scheduler" do
    let(:calculation_uuid_1)             { SecureRandom.uuid }
    let(:num_exercise_uuids_1)           { rand(10) + 1 }
    let(:exercise_uuids_1)               do
      num_exercise_uuids_1.times.map { SecureRandom.uuid }
    end

    let(:calculation_uuid_2)             { SecureRandom.uuid }
    let(:num_exercise_uuids_2)           { rand(10) + 1 }
    let(:exercise_uuids_2)               do
      num_exercise_uuids_2.times.map { SecureRandom.uuid }
    end

    let(:exercise_calculations)          do
      [
        {
          calculation_uuid: calculation_uuid_1,
          ecosystem_uuid: SecureRandom.uuid,
          student_uuid: SecureRandom.uuid,
          exercise_uuids: exercise_uuids_1
        },
        {
          calculation_uuid: calculation_uuid_2,
          ecosystem_uuid: SecureRandom.uuid,
          student_uuid: SecureRandom.uuid,
          exercise_uuids: exercise_uuids_2
        }
      ]
    end

    let(:expected_ex_uuids_by_calc_uuid) do
      {
        calculation_uuid_1 => exercise_uuids_1,
        calculation_uuid_2 => exercise_uuids_2
      }
    end

    it "sends a clue_calculation_update for each given clue_calculation to the scheduler" do
      expect(OpenStax::Biglearn::Scheduler).to(
        receive(:fetch_exercise_calculations)
      ).and_return(exercise_calculations: exercise_calculations)
      expect(OpenStax::Biglearn::Scheduler).to receive(:update_exercise_calculations) do |updates|
        updates.each do |update|
          expected_exercise_uuids = expected_ex_uuids_by_calc_uuid.fetch update[:calculation_uuid]
          expect(update[:algorithm_name]).to be_nil
          expect(update[:exercise_uuids]).to eq expected_exercise_uuids
        end
      end

      action
    end
  end
end
