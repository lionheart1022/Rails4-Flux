class CreateEconomicInvoicesFromReportDelayedJob
  
  def initialize(company_id: nil, report_id: nil)
    @company_id = company_id
    @report_id  = report_id
  end
  
  def enqueue
    Report.update_economic_invoices_state(company_id: @company_id, report_id: @report_id, state: Report::EconomicInvoices::States::IN_PROGRESS)
  end
  
  def perform
    generator = ReportEconomicInvoicesGenerator.new(company_id: @company_id, report_id: @report_id)
    report = generator.run
  end
  
  def success(job)
    Report.update_economic_invoices_state(company_id: @company_id, report_id: @report_id, state: Report::EconomicInvoices::States::SUCCESSFUL)
  end
  
  def error(job, exception)
    Rails.logger.error("[CreateEconomicInvoicesFromReportJob] Error executing job\n#{exception}")
    Report.update_economic_invoices_state(company_id: @company_id, report_id: @report_id, state: Report::EconomicInvoices::States::FAILED)
    ExceptionMonitoring.report(exception)
  end
  
  def failure
    Rails.logger.error("[CreateEconomicInvoicesFromReportJob] Failure executing job")
    Report.update_economic_invoices_state(company_id: @company_id, report_id: @report_id, state: Report::EconomicInvoices::States::FAILED)
  end
  
end
