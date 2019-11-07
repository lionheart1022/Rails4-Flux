class Companies::CustomerCarrierShowView
  attr_reader :current_company
  attr_reader :customer
  attr_reader :carrier

  def initialize(current_company:, customer_id:, carrier_id:)
    @current_company = current_company
    @customer = @current_company.customers.find(customer_id)
    @carrier = @current_company.find_enabled_carrier(carrier_id)
  end

  def customer_carrier_products
    current_company.all_carrier_products(carrier: @carrier).map do |carrier_product|
      customer_carrier_product = existing_customer_carrier_products.find { |customer_carrier_product| customer_carrier_product.carrier_product_id == carrier_product.id }
      customer_carrier_product || CustomerCarrierProduct.new(is_disabled: true, customer: customer, carrier_product: carrier_product)
    end
  end

  private

  def existing_customer_carrier_products
    @_existing_customer_carrier_products ||=
      CustomerCarrierProduct
      .includes(:carrier_product)
      .where(customer: customer)
      .where(carrier_products: { carrier_id: carrier.id })
  end
end
