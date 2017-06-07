class Services::CalculateExercises::Service < Services::ApplicationService
  def process
    exercise_calculations = OpenStax::Biglearn::Scheduler.fetch_exercise_calculations
                                                         .fetch(:exercise_calculations)
                                                         .map(&:symbolize_keys)

    exercise_calculation_updates = exercise_calculations.map do |exercise_calculation|
      {
        calculation_uuid: exercise_calculation.fetch(:calculation_uuid),
        exercise_uuids: exercise_calculation.fetch(:exercise_uuids).shuffle
      }
    end

    OpenStax::Biglearn::Scheduler.update_exercise_calculations exercise_calculation_updates
  end
end
