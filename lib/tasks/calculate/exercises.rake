namespace :calculate do
  task exercises: :environment do
    Services::CalculateExercises::Service.process
  end
end
