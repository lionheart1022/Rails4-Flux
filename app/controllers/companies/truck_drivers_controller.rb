class Companies::TruckDriversController < CompaniesController
  def index
    @truck_drivers = TruckDriver.where(company: current_company).enabled.ordered_by_name.page(params[:page])
  end

  def new
    @truck_driver = TruckDriver.new
  end

  def create
    @truck_driver = TruckDriver.new(company: current_company)
    @truck_driver.assign_attributes(truck_driver_params)

    if @truck_driver.save
      redirect_to companies_truck_drivers_path
    else
      render :new
    end
  end

  def show
    @truck_driver = TruckDriver.where(company: current_company).find(params[:id])
  end

  def update
    @truck_driver = TruckDriver.where(company: current_company).find(params[:id])
    @truck_driver.assign_attributes(truck_driver_params)

    if @truck_driver.save
      redirect_to companies_truck_drivers_path
    else
      render :edit
    end
  end

  def destroy
    @truck_driver = TruckDriver.where(company: current_company).find(params[:id])
    @truck_driver.disable!

    redirect_to companies_truck_drivers_path
  end

  private

  def truck_driver_params
    params.require(:truck_driver).permit(:name)
  end

  def set_current_nav
    @current_nav = "truck_drivers"
  end
end
