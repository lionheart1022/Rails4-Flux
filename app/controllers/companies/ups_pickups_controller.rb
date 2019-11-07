class Companies::UPSPickupsController < CompaniesController
  before_action :set_selected_customer
  helper_method :selected_customer

  def new
    @pickup = UPSPickup.new(company: current_company, customer: selected_customer)
    @pickup.build_contact_from_customer
  end

  def confirm
    @pickup = UPSPickup.new(pickup_params)
    @pickup.company = current_company
    @pickup.customer = selected_customer

    if @pickup.can_confirm?
      render :confirm
    else
      render :new
    end
  end

  def create
    @pickup = UPSPickup.new(pickup_params)
    @pickup.company = current_company
    @pickup.customer = selected_customer
    @pickup.save_and_enqueue_request!

    redirect_to companies_pickup_path(@pickup.record.id)
  end

  private

  def pickup_params
    params.fetch(:carrier_pickup, {}).permit(
      :pickup_date,
      :from_time,
      :to_time,
      :description,
      :company_name,
      :attention,
      :address_line1,
      :address_line2,
      :address_line3,
      :phone_number,
      :zip_code,
      :city,
      :country_code,
    )
  end

  def set_selected_customer
    @selected_customer = current_company.customers.find(params[:selected_customer_identifier])
  end

  def selected_customer
    @selected_customer
  end

  def set_current_nav
    @current_nav = "pickups"
  end
end
