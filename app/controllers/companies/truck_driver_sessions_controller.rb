class Companies::TruckDriverSessionsController < CompaniesController
  before_action :set_truck_driver

  def index
    @token_sessions = @truck_driver.token_sessions.order(id: :desc).page(params[:page]).per(100)
  end

  private

  def set_truck_driver
    @truck_driver = TruckDriver.where(company: current_company).find(params[:truck_driver_id])
  end

  def set_current_nav
    @current_nav = "truck_drivers"
  end
end
