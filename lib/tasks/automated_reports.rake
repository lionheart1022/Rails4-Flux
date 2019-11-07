namespace :automated_reports do
  desc "Generate scheduled reports"
  task handle_scheduled: :environment do
    AutomatedReportRequest.handle_requests_scheduled_to_run!
  end
end
