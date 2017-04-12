biglearn_scheduler_secrets = Rails.application.secrets['openstax']['biglearn']['scheduler']

OpenStax::Biglearn::Scheduler.configure do |config|
  config.server_url = biglearn_scheduler_secrets['url']
  config.client_id  = biglearn_scheduler_secrets['client_id']
  config.secret     = biglearn_scheduler_secrets['secret']
end

biglearn_scheduler_secrets.fetch('stub', false) ? OpenStax::Biglearn::Scheduler.use_fake_client :
                                                  OpenStax::Biglearn::Scheduler.use_real_client
