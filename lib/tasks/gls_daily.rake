namespace :gls_daily do
  desc "Fetch new daily update files via FTP"
  task :fetch_new, [] => [:environment] do |t, args|
    abort "Only use this in production" unless Rails.env.production?

    gls_daily = GLSDaily.new
    gls_daily.dry_run = ENV.fetch("DRY_RUN", "0") == "1"
    gls_daily.delete_processed_file = ENV.fetch("DELETE_PROCESSED_FILE", "1") == "1"
    gls_daily.perform!

    gls_daily.created_feedback_files.group_by(&:configuration_id).each do |_, feedback_files|
      # Only process a single feedback file per configuration to avoid potential issues of the same shipment in multiple files.
      feedback_file_id = feedback_files.first.id
      CarrierFeedbackJob.perform_later(feedback_file_id, auto_process: true)
    end
  end

  desc "Fetch special daily update file via FTP"
  task :fetch_special, [] => [:environment] do |t, args|
    abort "Only use this in production" unless Rails.env.production?

    gls_daily = GLSDailySpecial.new
    gls_daily.dry_run = false
    gls_daily.delete_processed_file = true
    gls_daily.perform!

    gls_daily.created_feedback_files.group_by(&:configuration_id).each do |_, feedback_files|
      # Only process a single feedback file per configuration to avoid potential issues of the same shipment in multiple files.
      feedback_file_id = feedback_files.first.id
      CarrierFeedbackJob.perform_later(feedback_file_id, auto_process: true)
    end
  end
end
