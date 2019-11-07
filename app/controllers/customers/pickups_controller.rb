class Customers::PickupsController < CustomersController
  def index
    @view_model = PickupsIndexView.new(
      base_relation: PickupsIndexView.base_index_relation_for_customer(company: current_company, customer: current_customer),
      available_states: PickupsIndexView::ACTIVE_STATES,
      state: params[:filter_state],
      sorting: params[:sorting],
    )
  end

  def archived
    @view_model = PickupsIndexView.new(
      base_relation: PickupsIndexView.base_archived_relation_for_customer(company: current_company, customer: current_customer),
      available_states: PickupsIndexView::ARCHIVED_STATES,
      state: params[:filter_state],
      sorting: params[:sorting],
    )
  end

  def show
    @pickup = Pickup.where(company: current_company, customer: current_customer).find(params[:id])
    @pickup_events = @pickup.events.order(created_at: :desc)
  end

  def new
    @pickup = Pickup.new
    @pickup.build_contact(current_customer.address.attributes)
  end

  def create
    @pickup = current_customer.create_pickup(pickup_params)

    if @pickup.errors.empty?
      flash[:success] = "Successfully created pickup"
      redirect_to customers_pickups_path
    else
      render :new
    end
  end

  private

  def pickup_params
    params.fetch(:pickup, {}).permit(
      :pickup_date,
      :from_time,
      :to_time,
      :description,
      :contact_attributes => [
        :company_name,
        :attention,
        :address_line1,
        :address_line2,
        :address_line3,
        :zip_code,
        :city,
        :country_code,
      ]
    )
  end

  def set_current_nav
    @current_nav = current_nav_value
  end

  def current_nav_value
    case action_name
    when "index"
      "pickups"
    when "archived"
      "pickups_archived"
    when "show"
      pickup = Pickup.find_customer_pickup(customer_id: current_customer.id, company_id: current_company.id, pickup_id: params[:id])

      if pickup && pickup.archived?
        "pickups_archived"
      else
        "pickups"
      end
    else
      "pickups"
    end
  end
end
