class EconomicInvoiceExport
  class << self
    def build_from_report(report)
      export = new(report: report)

      group_shipments_ms = Benchmark.ms { export.group_shipments_into_invoices }

      Rails.logger.tagged("EconomicInvoiceExport") do
        Rails.logger.info "Number of shipments (%d)" % [ report.shipments.count ]
        Rails.logger.info "Group shipments into invoices (%.1fms)" % [ group_shipments_ms ]
      end

      generate_invoice_lines_ms = Benchmark.ms { export.generate_invoice_lines }

      Rails.logger.tagged("EconomicInvoiceExport") do
        Rails.logger.info "Generate invoice lines (%.1fms)" % [ generate_invoice_lines_ms ]
      end

      export
    end

    def create_from_report!(report)
      export = build_from_report(report)

      save_invoices_ms = Benchmark.ms { export.save! }

      Rails.logger.tagged("EconomicInvoiceExport") do
        Rails.logger.info "Save invoices (%.1fms)" % [ save_invoices_ms ]
      end

      export
    end
  end

  attr_accessor :report

  def initialize(report:)
    self.report = report
    @invoice_map = {}
    @buyer_external_accounting_number_map = {}
  end

  def invoices
    invoice_map.values
  end

  def group_shipments_into_invoices
    ordered_invoiceable_shipments.each do |shipment|
      buyer = Shipment.find_company_or_customer_payer(current_company_id: seller_company.id, shipment_id: shipment.id)

      next if buyer.blank? # Should probably not happen but added just in case

      buyer_price = AdvancedPrice.find_by(shipment: shipment, buyer: buyer)
      currency = buyer_price.try(:sales_price_currency)

      next if currency.blank? # Skip shipments without prices (for the buyer)

      add_shipment_to_invoice(shipment: shipment, buyer: buyer, currency: currency)
    end
  end

  def generate_invoice_lines
    invoices.each do |invoice|
      invoice.shipments.each do |shipment|
        if report.with_detailed_pricing?
          invoice.build_lines_from_shipment(shipment)
        else
          invoice.build_simplified_lines_from_shipment(shipment)
        end
      end
    end
  end

  def seller_company
    report.company
  end

  def save!
    EconomicInvoiceRecord.transaction do
      invoices.each do |invoice|
        invoice.save!
        invoice.check_readiness!
      end
    end
  end

  private

  attr_reader :invoice_map
  attr_reader :buyer_external_accounting_number_map

  def ordered_invoiceable_shipments
    report.shipments.invoiceable.order(unique_shipment_id: :asc, id: :asc)
  end

  def add_shipment_to_invoice(shipment:, buyer:, currency:)
    buyer_key = [buyer.class.name, buyer.id]

    unless buyer_external_accounting_number_map.key?(buyer_key)
      buyer_external_accounting_number_map[buyer_key] = external_accounting_number_for_buyer(buyer)
    end

    invoice_key = [currency, buyer.class.name, buyer.id]

    unless invoice_map.key?(invoice_key)
      invoice_map[invoice_key] = EconomicInvoiceRecord.new(
        parent: report,
        seller: seller_company,
        buyer: buyer,
        external_accounting_number: buyer_external_accounting_number_map.fetch(buyer_key),
        currency: currency,
      )
    end

    invoice_map.fetch(invoice_key).shipments << shipment
  end

  def external_accounting_number_for_buyer(buyer)
    if buyer.is_a?(Customer)
      buyer.external_accounting_number
    elsif buyer.is_a?(Company)
      EntityRelation.find_carrier_product_customer_entity_relation(from_reference_id: report.company_id, to_reference_id: buyer.id).external_accounting_number
    else
      raise "Unknown buyer kind"
    end
  end
end
