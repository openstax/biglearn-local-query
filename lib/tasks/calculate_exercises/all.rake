namespace :calculate_exercises do
  task(all: :environment) do
    Services::CalculateExercises::Service.new.process
  end
end
