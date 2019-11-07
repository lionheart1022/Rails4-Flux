class Companies::TruckDriverUsersController < CompaniesController
  before_action :set_truck_driver

  def new
    @form = NewTruckDriverUserForm.new(current_company: current_company, truck_driver: @truck_driver)
  end

  def create
    @form = NewTruckDriverUserForm.new(current_company: current_company, truck_driver: @truck_driver)
    @form.assign_attributes(params.require(:user).permit(:email, :send_invitation_email))

    if @form.save
      redirect_to companies_truck_drivers_path
    else
      render :new
    end
  end

  def destroy
    @truck_driver.delete_associated_user!

    redirect_to companies_truck_drivers_path
  end

  private

  def set_truck_driver
    @truck_driver = TruckDriver.where(company: current_company).find(params[:truck_driver_id])
  end

  def set_current_nav
    @current_nav = "truck_drivers"
  end
end
