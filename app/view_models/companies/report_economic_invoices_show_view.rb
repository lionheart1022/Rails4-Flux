class Companies::ReportEconomicInvoicesShowView
  attr_accessor :current_company
  attr_accessor :report
  attr_accessor :invoice
  attr_accessor :page, :per_page

  def initialize(current_company:, report:, invoice:, page: nil, per_page: 100)
    self.current_company = current_company
    self.report = report
    self.invoice = invoice
    self.page = page
    self.per_page = per_page
  end

  def available_economic_products
    @available_economic_products ||= economic_access.products.order(:number, :name)
  end

  def paginated_invoice_lines
    invoice.ordered_lines.page(page).per(per_page)
  end

  def show_submit_buttons?
    invoice.still_editable?
  end

  private

  def economic_access
    @economic_access ||= EconomicAccess.active.find_by!(owner: current_company)
  end
end
