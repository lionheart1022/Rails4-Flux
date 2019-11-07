workers Integer(ENV['PUMA_WORKERS'] || 2)
min_thread_count, max_thread_count = ENV.fetch('PUMA_THREADS', '5:5').split(':', 2).map { |count| Integer(count) }
threads min_thread_count, max_thread_count

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end
