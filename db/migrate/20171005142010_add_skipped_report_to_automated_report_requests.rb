class AddSkippedReportToAutomatedReportRequests < ActiveRecord::Migration
  def change
    add_column :automated_report_requests, :skipped_report, :boolean
    add_column :automated_report_requests, :skipped_report_reason, :string
  end
end
