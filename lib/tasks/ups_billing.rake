namespace :ups_billing do
  desc "Fetch UPS billing file and turn that into a UPSFeedbackFile containing updates"
  task :fetch, [:config_id, :zip_file_name] => [:environment] do |t, args|
    config = UPSFeedbackConfiguration.find(args[:config_id])
    auto_process = ENV.fetch("AUTO_PROCESS", "0") == "1"

    feedback_file = config.download_zip_from_ftp!(args[:zip_file_name])
    puts "Downloaded ZIP file (ID: #{feedback_file.id}, original_filename: #{feedback_file.original_filename})"

    CarrierFeedbackJob.perform_later(feedback_file.id, auto_process: auto_process)
    puts "Enqueued job to parse file (auto_process: #{auto_process.inspect})"
  end

  task :report, [:config_id, :zip_file_name] => [:environment] do |t, args|
    config = UPSFeedbackConfiguration.find(args[:config_id])
    ftp_uri = config.ftp_uri
    zip_result = UPSBillingFTP.parse_zip_from_ftp(ftp_uri: ftp_uri, file_name: args[:zip_file_name])
    UPSBillingReport.print_from_zip_result(zip_result)
  end

  task :list, [:config_id] => [:environment] do |t, args|
    config = UPSFeedbackConfiguration.find(args[:config_id])
    ftp_uri = config.ftp_uri
    puts UPSBillingFTP.list_ftp_files(ftp_uri: ftp_uri)
  end
end
