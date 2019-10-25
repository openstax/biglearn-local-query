source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Use Rails' bootstrap process without Rails itself
gem 'railties', '~> 5.2.3'

# We use this gem to talk to biglearn-scheduler, even though it does not support OAuth
# This allows us to easily start using it in the future if we decide to
gem 'oauth2'

# URL manipulation
gem 'addressable'

# Daemonize our custom background tasks
gem 'daemons'

# Sentry integration
gem 'sentry-raven'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri

  # RSpec test framework
  gem 'rspec-rails'

  # Stubs HTTP requests
  gem 'webmock'

  # Records HTTP requests
  gem 'vcr'
end

group :development do
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen'

  # Re-run specs when files change
  gem 'spring-commands-rspec'
  # Needed for Guard to work on Ruby's built without readline
  gem 'rb-readline'
  gem 'guard-rspec'
end
