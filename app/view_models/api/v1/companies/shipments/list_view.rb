class API::V1::Companies::Shipments::ListView
  attr_reader :company, :shipments

  def initialize(company: nil, shipments: nil)
    @shipments = shipments
    @company = company

    state_general
  end

  def customer_external_accounting_number(shipment: nil)
    if shipment.customer.company == company
      shipment.customer.external_accounting_number.presence
    end
  end

  def company_advanced_price(shipment: nil)
    shipment.advanced_prices.select{ |ap| ap.seller_id == @company.id && ap.seller_type == Company.to_s }.first
  end

  private

  def state_general
    @main_view = "api/v1/companies/shipments/index"
  end
end
