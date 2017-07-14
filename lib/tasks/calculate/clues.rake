namespace :calculate do
  task clues: :environment do
    Services::CalculateClues::Service.process
  end
end
