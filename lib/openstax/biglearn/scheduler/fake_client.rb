module OpenStax
  module Biglearn
    module Scheduler
      class FakeClient
        def initialize(biglearn_scheduler_configuration)
        end

        def fetch_clue_calculations(request)
          { clue_calculations: [] }
        end

        def fetch_exercise_calculations(request)
          { exercise_calculations: [] }
        end

        def update_clue_calculations(requests)
          requests.map do |request|
            {
              calculation_uuid: request[:calculation_uuid],
              calculation_status: 'calculation_accepted'
            }
          end
        end

        def update_exercise_calculations(requests)
          requests.map do |request|
            {
              calculation_uuid: request[:calculation_uuid],
              calculation_status: 'calculation_accepted'
            }
          end
        end
      end
    end
  end
end
