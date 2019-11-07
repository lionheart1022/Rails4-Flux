class Companies::DeliveriesController < CompaniesController
  def show
    @delivery = Delivery.where(company: current_company).find(params[:id])
    @delivery_shipments = @delivery.shipments
      .order(shipping_date: :asc, id: :asc)
      .includes(:customer, :sender, :recipient, :carrier_product, :asset_awb, :company)
  end

  def destroy
    delivery = Delivery.where(company: current_company).find(params[:id])
    delivery.empty_truck
    redirect_to companies_truck_fleet_path
  end

  private

  def set_current_nav
    @current_nav = "truck_fleet"
  end
end
