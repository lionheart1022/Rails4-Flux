class Companies::ReportEconomicInvoicesListView
  attr_accessor :current_company
  attr_accessor :report

  def initialize(current_company:, report:)
    self.current_company = current_company
    self.report = report
  end

  def invoices
    @invoices ||= EconomicInvoiceRecord.includes(:ordered_lines, :buyer).where(parent: @report).order(:id)
  end

  def available_economic_products
    @available_economic_products ||= economic_access.products.order(:number, :name)
  end

  def show_submit_buttons?
    invoices.select { |invoice| invoice.still_editable? }.count > 0
  end

  private

  def economic_access
    @economic_access ||= EconomicAccess.active.find_by!(owner: current_company)
  end
end
