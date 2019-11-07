class GenerateExcelReportJob < ActiveJob::Base
  queue_as :reports

  after_enqueue do |job|
    Report.find(job.arguments.first).update!(state: Report::States::IN_PROGRESS)
  end

  def perform(report_id)
    report = Report.find(report_id)

    begin
      report.generate_excel_report_now!
      report.update!(state: Report::States::SUCCESSFUL)
    rescue => e
      report.update!(state: Report::States::FAILED)

      ExceptionMonitoring.report!(e)
    end
  end
end
