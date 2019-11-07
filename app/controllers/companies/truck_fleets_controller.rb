class Companies::TruckFleetsController < CompaniesController
  def show
    @trucks = Truck.where(company: current_company).enabled.ordered_by_name
  end

  private

  def set_current_nav
    @current_nav = "truck_fleet"
  end
end
