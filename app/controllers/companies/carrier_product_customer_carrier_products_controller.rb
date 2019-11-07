class Companies::CarrierProductCustomerCarrierProductsController < CompaniesController
  before_action :customer, :customer_carrier

  def index
    carrier_id  = params[:carrier_product_customer_carrier_id]
    carrier = Carrier.find_company_carrier(company_id: @customer.id, carrier_id: carrier_id)

    carrier_products = CarrierProduct.includes(:customer_carrier_products, :sales_price).find_company_carrier_products(company_id: @customer.id, carrier_id: @customer_carrier.id).sort_by { |p| p.name.downcase }
    @view_model      = Companies::CarrierProductCustomers::Carriers::Products::ListView.new(customer: @customer, carrier: carrier, carrier_products: carrier_products)
  end

  def new
    owner_carrier_products = CarrierProduct.find_company_carrier_products(company_id: current_company.id, carrier_id: @customer_carrier.carrier_id)
    customer_company_carrier_products = CarrierProduct.find_company_carrier_products(company_id: @customer.id, carrier_id: @customer_carrier.id)
    customer_company_carrier_product_parent_ids = customer_company_carrier_products.map(&:carrier_product_id)

    owner_carrier_products = owner_carrier_products.select do |carrier_product|
      !customer_company_carrier_product_parent_ids.include?(carrier_product.id)
    end

    @view_model = Companies::CarrierProductCustomers::Carriers::Products::FormView.new(customer: @customer, carrier: @customer_carrier, products: owner_carrier_products)
  end

  def create
    ids_with_options = params[:carrier_products].to_a.map do |obj|
      hash = obj.last
      hash[:carrier_product_id] = obj.first
      hash[:add_product] = hash[:add_product] == '1'

      hash
    end

    interactor = Companies::CarrierProductCustomers::Carriers::Products::AddProductsToCustomerCompanyCarrier.new(
      company_id: current_company.id,
      customer_company_id: @customer.id,
      customer_carrier_id: @customer_carrier.id,
      data: ids_with_options
    )

    result = interactor.run
    if error = result.try(:error)
      flash[:error] = error.message
    else
      count           = result.added_count
      pluralized_noun = 'product'.pluralize(count)
      message         = "Successfully added #{count} #{pluralized_noun}"
      flash[:success] = message
    end
    redirect_to companies_carrier_product_customer_carrier_product_customer_carrier_carrier_product_customer_carrier_products_path(@customer.id, @customer_carrier.id)
  end

  def set_carrier_products_and_sales_prices
    with_carrier_product_ids = params[:carrier_products].to_a.map do |obj|
      hash = obj[1]
      hash[:carrier_product_id] = obj[0]
      hash
    end
    carrier_product_options = with_carrier_product_ids.each.map do |obj|
      {
        carrier_product_id:      obj[:carrier_product_id].to_i,
        margin_percentage:       obj[:sales_price][:margin_percentage],
        is_disabled:             obj[:is_disabled] == '0'
      }
    end

    interactor = Companies::CarrierProductCustomers::SetCarrierProductsAndSalesPrices.new(company_id: current_company.id, customer_id: @customer.id, carrier_product_options: carrier_product_options)

    result = interactor.run
    if result.try(:error)
      flash[:error]   = "An error occured"
    else
      flash[:success] = "Successfully updated available carrier products"
    end
    redirect_to companies_carrier_product_customer_carrier_product_customer_carriers_path(customer)
  end

  def customer
    customer_id = params[:carrier_product_customer_id]
    @customer = ::Company.find_carrier_product_customer(company_id: current_company.id, customer_id: customer_id)
  end

  def customer_carrier
    customer_carrier_id = params[:carrier_product_customer_carrier_id]
    @customer_carrier = Carrier.find_company_carrier(company_id: self.customer.id, carrier_id: customer_carrier_id)
  end

  def set_current_nav
    @current_nav = "carrier_product_customers"
  end

end
