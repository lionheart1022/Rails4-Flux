class Companies::ShipmentRequestPricesController < CompaniesController
  include GetCarrierProductsAndPricesForShipment

  before_action :set_selected_customer

  def create
    perform_get_carrier_products_and_prices_for_shipment!(
      company_id: current_company.id,
      customer_id: selected_customer.id,
      chain: false,
      custom_products_only: true,
    )
  rescue => e
    ExceptionMonitoring.report!(e)
  end

  private

  def set_selected_customer
    @selected_customer = current_company.customers.find(params[:selected_customer_identifier])
  end

  def selected_customer
    @selected_customer
  end
end
