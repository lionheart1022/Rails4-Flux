class Companies::CarrierProductCustomers::Carriers::ListView
  attr_reader :main_view, :customer, :carriers, :entity_relation, :current_company

  def initialize(current_company: nil, customer: nil, carriers: nil, entity_relation: nil)
    @current_company  = current_company
    @customer         = customer
    @carriers         = carriers
    @entity_relation = entity_relation
    state_general
  end

  def state
    "#{customer.address.state_name} (#{customer.address.state_code})"
  end

  private

  def state_general
    @main_view = "components/companies/carrier_product_customers/carriers/index"
  end
end
