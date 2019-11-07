class Companies::PickupsController < CompaniesController
  def index
    @filter = PickupFilter.active_for_company(current_company, params: filter_params)
    @filter.perform!
  end

  def archived
    @filter = PickupFilter.archived_for_company(current_company, params: filter_params)
    @filter.perform!
  end

  def show
    @pickup = Pickup.find_company_pickup(company_id: current_company.id, pickup_id: params[:id])
    @pickup_events = @pickup.events.order(created_at: :desc)
  end

  private

  def filter_params
    {
      customer_id: params[:filter_customer_id],
      state: params[:filter_state],
      grouping: params[:grouping],
      sorting: params[:sorting],
      pagination: true,
      page: params[:page],
    }
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
    else
      pickup = Pickup.find_company_pickup(company_id: current_company.id, pickup_id: params[:id])

      if pickup && pickup.archived?
        "pickups_archived"
      else
        "pickups"
      end
    end
  end
end
