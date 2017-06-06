class Services::CalculateClues::Service < Services::ApplicationService
  MIN_NUM_RESPONSES = 3 # Must be 2 or more to prevent division by 0
  Z_ALPHA = 0.68
  Z_ALPHA_SQUARED = Z_ALPHA**2

  def process
    clue_calculations = OpenStax::Biglearn::Scheduler.fetch_clue_calculations
                                                     .fetch(:clue_calculations)
                                                     .map(&:deep_symbolize_keys)

    clue_calculation_updates = clue_calculations.map do |clue_calculation|
      calculation_uuid = clue_calculation.fetch :calculation_uuid
      responses = clue_calculation.fetch :responses
      ecosystem_uuid = clue_calculation.fetch :ecosystem_uuid

      trial_tot = responses.count
      clue_data = self.class.calculate_clue(responses, ecosystem_uuid)

      {
        calculation_uuid: calculation_uuid,
        clue_data: clue_data
      }
    end

    OpenStax::Biglearn::Scheduler.update_clue_calculations clue_calculation_updates
  end

  protected

  def self.calculate_clue(responses, ecosystem_uuid)
    grouped_responses = responses.group_by { |response| response[:trial_uuid] }
    trial_correctnesses = grouped_responses.map do |trial_uuid, responses|
      responses.last[:is_correct]
    end

    trial_tot = trial_correctnesses.count
    clue_data = if trial_tot >= MIN_NUM_RESPONSES
      trial_suc = trial_correctnesses.count{ |bool| bool }

      p_hat = (trial_suc + 0.5 * Z_ALPHA_SQUARED) / (trial_tot + Z_ALPHA_SQUARED)

      var = trial_correctnesses.map do |trial_correctness|
        value = trial_correctness ? 1 : 0

        (p_hat - value)**2
      end.reduce(:+) / (trial_tot - 1)

      interval = ( Z_ALPHA * Math.sqrt(p_hat * (1 - p_hat)/(trial_tot + Z_ALPHA_SQUARED)) +
                   0.1 * Math.sqrt(var) + 0.05 )

      {
        minimum: [p_hat - interval, 0].max,
        most_likely: p_hat,
        maximum: [p_hat + interval, 1].min,
        is_real: true,
        ecosystem_uuid: ecosystem_uuid
      }
    else
      {
        minimum: 0,
        most_likely: 0.5,
        maximum: 1,
        is_real: false,
        ecosystem_uuid: ecosystem_uuid
      }
    end
  end
end
