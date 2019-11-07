class Companies::ShipmentDeliveriesController < CompaniesController
  before_action :find_records

  def update
    interactor = Companies::ShipmentDeliveriesUpdater.new(shipment: @shipment, truck: @truck, driver: @driver, current_context: current_context, selected_truck_and_driver: select_truck_and_driver)
    interactor.perform

    redirect_to companies_shipment_path(@shipment)
  end

  private

  def select_truck_and_driver
    shipment_params["shipment_select_truck_and_driver"]
  end

  def find_records
    @shipment = Shipment.where(company: current_company).find(shipment_params["shipment_id"])
    @truck = Truck.where(company: current_company).find_by(id: shipment_params["truck_id"])
    @driver = TruckDriver.where(company: current_company).find_by(id: shipment_params["driver_id"])
  end

  def shipment_params
    params.permit(:shipment_select_truck_and_driver, :truck_id, :driver_id, :shipment_id)
  end
end
