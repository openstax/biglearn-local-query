include Tasks::ApplicationHelper

namespace :calculate_clues do
  define_worker_tasks :'calculate_clues:all'
end
