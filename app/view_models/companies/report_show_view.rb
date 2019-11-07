class Companies::ReportShowView
  attr_reader :current_company
  attr_reader :report
  attr_reader :page

  def initialize(current_company:, report:, page: nil)
    @current_company = current_company
    @report = report
    @page = page
  end

  def scoped_report_id
    report.report_id
  end

  def shipments
    @paginated_shipments ||=
      report
      .ordered_shipments
      .includes(:carrier_product, :recipient)
      .page(page)
      .per(50)
  end

  def show_loading_indicator?
    report.in_progress?
  end

  def show_download_button?
    report.successful?
  end

  def download_url
    report.download_url
  end

  def show_export_to_economic_button?
    if economic_access.nil? && economic_setting.try(:agreement_grant_token).present?
      [Report::EconomicInvoices::States::FAILED, nil].include?(report.economic_invoices_state)
    else
      false
    end
  end

  def show_v2_export_to_economic_button?
    return false if report.has_economic_invoice_export?
    return false if any_economic_invoices?

    if economic_access.present?
      [Report::EconomicInvoices::States::FAILED, nil].include?(report.economic_invoices_state)
    else
      false
    end
  end

  def show_v2_economic_invoices_button?
    report.has_economic_invoice_export? || any_economic_invoices?
  end

  private

  def economic_setting
    @economic_setting ||= EconomicSetting.find_for_company(company_id: current_company.id)
  end

  def economic_access
    if defined?(@economic_access)
      @economic_access
    else
      @economic_access = EconomicAccess.active.find_by(owner: current_company)
    end
  end

  def any_economic_invoices?
    if defined?(@any_economic_invoices)
      @any_economic_invoices
    else
      @any_economic_invoices = EconomicInvoiceRecord.where(parent: report).exists?
    end
  end
end
