class Companies::ShipmentDeliveriesUpdater
  attr_reader :shipment, :truck, :driver, :selected_truck_and_driver, :current_context

  def initialize(shipment:, truck:, driver:, current_context:, selected_truck_and_driver:)
    @shipment = shipment
    @truck = truck
    @driver = driver
    @current_context = current_context

    @selected_truck_and_driver = true_ish?(selected_truck_and_driver) 
  end

  def perform
    return unless is_product_owner?

    if latest_delivery_nil_or_done?

      if assign_truck_and_driver_for_shipment?
        create_new_delivery_for_shipment
      end

    elsif latest_delivery_is_in_transit?
      
      if assign_truck_and_driver_for_shipment?
        move_shipment_to_new_assigned_delivery
    
      elsif delete_truck_and_driver_for_shipment?
        remove_shipment_from_current_delivery
      end
    end
  end

  private

  def current_company
    current_context.company
  end
  
  def is_product_owner?
    shipment.carrier_product.product_responsible == current_company
  end

  def latest_delivery_nil_or_done?
    latest_delivery = shipment.deliveries.last
    latest_delivery.nil? || latest_delivery.done?
  end

  def latest_delivery_is_in_transit?
    latest_delivery = shipment.deliveries.last
    latest_delivery.present? && latest_delivery.in_transit?
  end

  def create_new_delivery_for_shipment
    active_delivery = truck.find_or_create_active_delivery
    # assign new driver
    active_delivery.truck_driver = driver
    shipment.deliveries << active_delivery
  end

  def move_shipment_to_new_assigned_delivery
    active_delivery = truck.find_or_create_active_delivery
    # assign new driver
    active_delivery.truck_driver = driver
    # omit this shipment from the previously assigned delivery
    shipment.deliveries.delete shipment.deliveries.last if shipment.deliveries.last
    # then put it in the new truck delivery
    shipment.deliveries << active_delivery
  end

  def remove_shipment_from_current_delivery
    shipment.deliveries.delete shipment.deliveries.last if shipment.deliveries.last
  end

  def assign_truck_and_driver_for_shipment?
    selected_truck_and_driver && truck.present? && !current_context.is_customer?
  end

  def delete_truck_and_driver_for_shipment?
    !selected_truck_and_driver || !truck.present?
  end

  def true_ish?(value)
    ["1", "true"].include?(value.to_s)
  end
end
