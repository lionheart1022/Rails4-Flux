class Companies::PickupStateChangesController < CompaniesController
  def create
    @pickup = Pickup.find_company_pickup(company_id: current_company.id, pickup_id: params[:pickup_id])

    interactor =
      Companies::ProcessPickupStateChange.new(
        company: current_company,
        pickup: @pickup,
        state_change_params: state_change_params,
      )

    interactor.perform!

    respond_to do |format|
      format.js
      format.html { redirect_to companies_pickup_path(@pickup) }
    end
  end

  private

  def state_change_params
    params.fetch(:pickup, {}).permit(:state, :comment)
  end
end
