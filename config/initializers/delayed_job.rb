if ["staging", "development"].include?(Rails.env)
  Delayed::Worker.sleep_delay = 5
else
  Delayed::Worker.sleep_delay = 2
end
Delayed::Worker.destroy_failed_jobs = true
Delayed::Worker.max_attempts = 1
Delayed::Worker.max_run_time = 10.minutes
Delayed::Worker.read_ahead = 10
Delayed::Worker.default_queue_name = 'default'
Delayed::Worker.delay_jobs = !Rails.env.test?
