include Tasks::ApplicationHelper

namespace :calculate_exercises do
  define_worker_tasks :'calculate_exercises:all'
end
