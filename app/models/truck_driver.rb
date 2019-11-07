class TruckDriver < ActiveRecord::Base
  belongs_to :company, required: true
  belongs_to :user, required: false
  has_many :shipment_associations, class_name: "ShipmentTruckDriver"
  has_many :shipments, through: :shipment_associations
  has_many :token_sessions, as: :sessionable
  has_and_belongs_to_many :deliveries

  scope :enabled, -> { where(disabled_at: nil) }
  scope :disabled, -> { where.not(disabled_at: nil) }
  scope :ordered_by_name, -> { order(:name) }

  validates :name, presence: true, uniqueness: { scope: :company_id, case_sensitive: false, conditions: -> { enabled } }

  class << self
    def authenticate_with_token(token_value, options)
      TruckDriverSession.find_by(id: options["t_id"], token_value: token_value)
    end
  end

  def disable!
    touch :disabled_at

    token_sessions.active.update_all(expired_at: Time.zone.now, expiration_reason: "disabled:truck_driver")
  end

  def delete_associated_user!
    transaction do
      if user
        token_sessions.active.update_all(expired_at: Time.zone.now, expiration_reason: "deleted:truck_driver_user")
        update!(user: nil)
      end
    end
  end

  def enabled?
    disabled_at.nil?
  end

  def disabled?
    !enabled?
  end
end
