class Companies::EconomicInvoicesController < CompaniesController
  def index
    @report = Report.where(company_id: current_company.id).find(params[:report_id])

    if params[:auto_redirect] == "1" && @report.in_progress_economic_invoice_export?
      redirect_to in_progress_companies_report_economic_invoice_export_path(@report)
      return
    end

    if params[:auto_redirect] == "1" && @report.economic_invoices.count == 1
      redirect_to companies_report_economic_invoice_path(@report, @report.economic_invoices.first)
      return
    end

    @view_model = ::Companies::ReportEconomicInvoicesListView.new(current_company: current_company, report: @report)
  end

  def show
    @report = current_company.reports.find(params[:report_id])
    @invoice = @report.economic_invoices.find(params[:id])
    @view_model = ::Companies::ReportEconomicInvoicesShowView.new(
      current_company: current_company,
      report: @report,
      invoice: @invoice,
      page: params[:page],
    )
  end

  def bulk_update
    @report = Report.where(company_id: current_company.id).find(params[:report_id])
    EconomicInvoiceRecord.bulk_update!(parent: @report, bulk_update_params: bulk_update_params)

    if params[:send_to_economic] == "1"
      EconomicInvoiceRecord.where(parent: @report).ready.not_sent.update_all(job_enqueued_at: Time.now)
      EconomicInvoiceRequestJob.perform_later(@report.id, current_company.id)
      redirect_to in_progress_companies_report_economic_invoices_path(@report)
    elsif params[:current_invoice_id].present?
      redirect_to companies_report_economic_invoice_path(@report, params[:current_invoice_id], page: params[:next_page].presence)
    else
      redirect_to companies_report_economic_invoices_path(@report)
    end
  end

  def in_progress
    @report = Report.where(company_id: current_company.id).find(params[:report_id])

    respond_to do |format|
      format.html
      format.json do
        in_progress_invoices = EconomicInvoiceRecord.enqueued.not_sent.where(parent: @report)

        render json: { result: in_progress_invoices.count == 0 }
      end
    end
  end

  private

  def bulk_update_params
    params.fetch(:bulk_update, {}).permit(
      :invoices => [
        :id,
        :external_accounting_number,
        :invoice_lines => [
          :id,
          :product_number,
        ],
      ]
    )
  end

  def set_current_nav
    @current_nav = "customers_reports"
  end
end
