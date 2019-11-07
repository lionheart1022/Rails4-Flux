class Companies::CarrierProductCustomers::Carriers::FormView
  attr_reader :main_view, :customer, :carriers

  def initialize(customer: nil, carriers: nil)
    @customer = customer
    @carriers = carriers
    state_general
  end

  def header_text
    "#{customer.name} - Add Carriers"
  end

  def show_table?
    @carriers.count > 0
  end

  private

  def state_general
    @main_view = "components/companies/carrier_product_customers/carriers/form"
  end
end
