class Companies::CarrierProductCustomers::Carriers::Products::FormView
  attr_reader :main_view, :customer, :carrier, :products

  def initialize(customer: nil, carrier: nil, products: nil)
    @customer = customer
    @carrier = carrier
    @products = products
    state_general
  end

  def header_text
    "#{customer.name} - Add #{carrier.name} Products"
  end

  def show_table?
    @products.count > 0
  end

  private

  def state_general
    @main_view = "components/companies/carrier_product_customers/carriers/products/form"
  end
end
