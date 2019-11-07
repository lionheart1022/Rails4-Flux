class Companies::TrucksController < CompaniesController
  def index
    @trucks = Truck.where(company: current_company).enabled.ordered_by_name.page(params[:page])
  end

  def new
    @truck = Truck.new(company: current_company)
  end

  def create
    @truck = Truck.new(company: current_company)
    @truck.assign_attributes(truck_params)
    if @truck.valid?
      @truck.company_truck_number = current_company.update_next_truck_number
      @truck.save
      redirect_to companies_trucks_path
    else
      render :new
    end
  end

  def show
    @truck = Truck.where(company: current_company).find(params[:id])
  end

  def update
    @truck = Truck.where(company: current_company).find(params[:id])
    @truck.assign_attributes(truck_params)

    if @truck.save
      redirect_to companies_trucks_path
    else
      render :edit
    end
  end

  def destroy
    @truck = Truck.where(company: current_company).find(params[:id])
    @truck.disable!

    redirect_to companies_trucks_path
  end

  private

  def truck_params
    params.require(:truck).permit(:name, :default_driver_id)
  end

  def set_current_nav
    @current_nav = "trucks"
  end
end
