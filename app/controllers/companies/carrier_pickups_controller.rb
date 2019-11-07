class Companies::CarrierPickupsController < CompaniesController
  # GET /companies/carrier_pickups/select_customer
  def select_customer
    @customers = Customer.find_company_customers(company_id: current_company.id).order(:customer_id).page(params[:page]).per(50)
  end

  # GET /companies/customers/:selected_customer_identifier/select_carrier
  def select_carrier
    # Currently we only support UPS; when we support more this action should render a list you can choose from.
    # Or a better way would be to have the user select the carrier when pressing the "Book new pickup" button in index.
    redirect_to new_companies_customer_scoped_ups_pickup_path
  end
end
