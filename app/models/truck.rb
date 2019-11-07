class Truck < ActiveRecord::Base
  belongs_to :company, required: true
  has_many :deliveries
  belongs_to :active_delivery, class_name: 'Delivery'
  belongs_to :default_driver, class_name: 'TruckDriver'

  scope :enabled, -> { where(disabled_at: nil) }
  scope :disabled, -> { where.not(disabled_at: nil) }
  scope :ordered_by_name, -> { order(:name) }

  validates :name, presence: true, uniqueness: { scope: :company_id, case_sensitive: false, conditions: -> { enabled } }

  def find_or_create_active_delivery
    if active_delivery.nil?
      truck_delivery_number = update_next_delivery_number
      new_active_delivery = deliveries.create(truck_delivery_number: truck_delivery_number, company: company, state: Delivery::States::IN_TRANSIT)
      new_active_delivery.create_unique_delivery_number
      update_attributes(active_delivery: new_active_delivery)
    end
    active_delivery
  end

  def update_next_delivery_number
    self.with_lock do
      self.increment!(:current_delivery_number)
    end
    return self.current_delivery_number
  end

  def available_truck_drivers
    TruckDriver.where(company: company)
  end

  def suggested_driver_id
    if active_delivery && active_delivery.truck_driver
      active_delivery.truck_driver.id
    else
      default_driver_id
    end
  end

  def disable!
    touch :disabled_at
  end

  def enabled?
    disabled_at.nil?
  end

  def disabled?
    !enabled?
  end
end
