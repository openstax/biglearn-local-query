namespace :calculate_clues do
  task all: :environment do
    Services::CalculateClues::Service.process
  end
end
