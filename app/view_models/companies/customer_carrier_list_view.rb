class Companies::CustomerCarrierListView
  attr_reader :current_company
  attr_reader :customer

  def initialize(current_company:, customer: nil, customer_id: nil)
    @current_company = current_company
    @customer = customer || @current_company.customers.find(customer_id)
    @index = -1
  end

  def carriers
    @_carriers ||= current_company.list_enabled_carriers
  end

  def current_index
    @index
  end

  def next_index
    @index += 1
  end

  def customer_carrier_products(carrier:)
    enabled_customer_carrier_products
      .select { |customer_carrier_product| customer_carrier_product.carrier_product.carrier_id == carrier.id }
      .sort_by { |customer_carrier_product| customer_carrier_product.carrier_product.name.downcase }
  end

  private

  def enabled_customer_carrier_products
    @_customer_carrier_products ||= CustomerCarrierProduct.includes(:carrier_product).where(customer: customer, is_disabled: false)
  end
end
