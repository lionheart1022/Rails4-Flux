class Companies::CarrierProductCustomerCarriersController < CompaniesController
  before_action :customer

  def index
    carriers    = Carrier.find_customer_company_carriers(company_id: current_company.id, customer_company_id: @customer.id)
    entity_relation = EntityRelation.find_carrier_product_customer_entity_relation(from_reference_id: current_company.id, to_reference_id: params[:carrier_product_customer_id])
    Rails.logger.debug carriers
    @view_model = Companies::CarrierProductCustomers::Carriers::ListView.new(
      current_company: current_company,
      customer: @customer,
      carriers: carriers,
      entity_relation: entity_relation
    )
  end

  def new
    owner_carriers = Carrier.find_company_carriers(company_id: current_company.id)
    customer_company_carriers = Carrier.find_customer_company_carriers(company_id: current_company.id, customer_company_id: @customer.id)
    customer_company_carrier_parent_ids = customer_company_carriers.map(&:carrier_id)

    owner_carriers = owner_carriers.select do |carrier|
      !customer_company_carrier_parent_ids.include?(carrier.id)
    end

    owner_carriers = owner_carriers.sort_by { |carrier| carrier.name.downcase }
    @view_model = Companies::CarrierProductCustomers::Carriers::FormView.new(customer: @customer, carriers: owner_carriers)
  end

  def create
    ids_with_options = params[:carriers].to_a.map do |obj|
      hash = obj.last
      hash[:carrier_id] = obj.first
      hash[:add_carrier] = hash[:add_carrier] == '1'
      hash[:add_products] = hash[:add_products] == '1'

      hash
    end

    interactor = Companies::CarrierProductCustomers::Carriers::AddCarriersToCustomerCompany.new(company_id: current_company.id, customer_company_id: @customer.id, data: ids_with_options)
    result = interactor.run

    if error = result.try(:error)
      flash[:error] = error.message
    else
      count           = result.added_count
      pluralized_noun = 'carrier'.pluralize(count)
      message         = "Successfully added #{count} #{pluralized_noun}"
      flash[:success] = message
    end
    redirect_to companies_carrier_product_customer_carrier_product_customer_carriers_path
  end


  def batch_disable
    carrier_product_customer_id = params[:carrier_product_customer_id]

    carrier_params = params[:carriers].to_a
    carrier_params = carrier_params.map{ |t| [t[1][:disabled] == '0', t[0] ]}

    interactor = Companies::Carriers::BatchDisableCarriers.new(company_id: current_company.id, carrier_product_customer_id: carrier_product_customer_id, carrier_params: carrier_params)
    result     = interactor.run
    if result.try(:error)
      flash[:error]   = "An error occured"
    else
      flash[:success] = "Successfully updated carriers"
    end

    redirect_to companies_carrier_product_customer_carrier_product_customer_carriers_path(carrier_product_customer_id)
  end

  private

  def customer
    customer_id = params[:carrier_product_customer_id]
    @customer = @customer || ::Company.find_carrier_product_customer(company_id: current_company.id, customer_id: customer_id)
  end

  def set_current_nav
    @current_nav = "carrier_product_customers"
  end

end
