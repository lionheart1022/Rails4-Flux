class ReportEconomicInvoicesGenerator
  
  attr_reader :company, :report, :shipments, :invoices
  
  def initialize(company_id: nil, report_id: nil)
    @company_id = company_id
    @report_id  = report_id
  end
  
  def run
    @company = Company.find_company(company_id: @company_id)
    @report = Report.find_company_report(company_id: @company_id, report_id: @report_id)
    
    # Only select shipments in a state that needs invoicing.
    @shipments = report.shipments.invoiceable.order("unique_shipment_id asc")
    @invoices = []
    
    build_invoices_for_shipments
    create_economic_draft_invoices
  end
  
  private
    
    def build_invoices_for_shipments
      shipments.each do |shipment|
        recipient = Shipment.find_company_or_customer_payer(current_company_id: company.id, shipment_id: shipment.id)
        currency = AdvancedPrice.find_buyer_shipment_price(shipment_id: shipment.id, buyer_id: recipient.id, buyer_type: recipient.class.name).try(:sales_price_currency)
        
        # Some shipments don't have any prices so only invoice if there is an advanced_price with a currency
        if currency
          invoice = invoices.find {|i| i.currency == currency && i.recipient_company_or_customer == recipient }
          
          # If it's the first time that we encounter recipient/currency combination, then add an invoice
          unless invoice
            invoice = EconomicInvoice.new(sender_company: company, recipient_company_or_customer: recipient, currency: currency)
            invoices.push(invoice)
          end
          
          invoice.add_shipment(shipment)
        end
      end
    end
    
    def create_economic_draft_invoices
      invoices.each do |invoice|
        invoice.create_economic_draft_invoice
      end
    end
    
end
