class Delivery < ActiveRecord::Base
  module States
    IN_TRANSIT = 'in_transit'
    EMPTY = 'empty'
  end

  belongs_to :truck
  belongs_to :company
  has_and_belongs_to_many :shipments
  has_one :truck_driver_association, class_name: "DeliveryTruckDriversJoinModel"
  has_one :truck_driver, through: :truck_driver_association

  validates :state, presence: true

  def in_transit?
    state == States::IN_TRANSIT
  end

  def done?
    state == States::EMPTY
  end

  def shipments_total_weight
    shipments.to_a.sum(&:total_weight)
  end

  def create_unique_delivery_number
    unique_delivery_number = "#{truck_id}-#{truck.company_truck_number}-#{truck_delivery_number}"
    update_attributes(unique_delivery_number: unique_delivery_number)
  end

  def shipments_count
    shipments.count
  end

  def empty_truck
    transaction do
      update!(state: Delivery::States::EMPTY)
      truck.update!(active_delivery: nil)
    end
  end

  def unique_delivery_number_with_prefix
    "D#{unique_delivery_number}"
  end

  def human_readable_state
    case state
    when States::IN_TRANSIT
      "In transit"
    when States::EMPTY
      "Empty"
    end
  end

  class DeliveryTruckDriversJoinModel < ActiveRecord::Base
    self.table_name = "deliveries_truck_drivers"

    belongs_to :truck_driver
    belongs_to :delivery
  end
end
