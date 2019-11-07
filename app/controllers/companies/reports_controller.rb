class Companies::ReportsController < CompaniesController
  def index
    @reports =
      current_company.reports
      .includes(:customer_recording)
      .order(id: :desc)
      .page(params[:page])
  end

  def show
    report = Report.where(company_id: current_company.id).find(params[:id])
    @view_model = ::Companies::ReportShowView.new(current_company: current_company, report: report, page: params[:page])
  end

  def export_economic
    report_id = params[:id]
    job = CreateEconomicInvoicesFromReportDelayedJob.new(company_id: current_company.id, report_id: report_id)
    Delayed::Job.enqueue(job, queue: Report::Queues::REPORTS)
    redirect_to companies_report_path(report_id)
  end

  private

  def set_current_nav
    @current_nav = "customers_reports"
  end
end
