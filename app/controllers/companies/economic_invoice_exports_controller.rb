class Companies::EconomicInvoiceExportsController < CompaniesController
  def create
    @report = current_company.reports.find(params[:report_id])
    @report.create_economic_invoices_later!

    redirect_to companies_report_economic_invoices_path(@report, auto_redirect: "1")
  end

  def in_progress
    @report = current_company.reports.find(params[:report_id])

    respond_to do |format|
      format.html
      format.json do
        render json: { result: @report.no_in_progress_economic_invoice_export? }
      end
    end
  end

  private

  def set_current_nav
    @current_nav = "customers_reports"
  end
end
