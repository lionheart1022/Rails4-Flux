module ShipmentRouteConstraint
  def self.match_regular_shipments(param_key = :id)
    RegularConstraint.new(param_key)
  end

  def self.match_ferry_booking_shipments(param_key = :id)
    FerryBookingConstraint.new(param_key)
  end

  class RegularConstraint
    attr_accessor :param_key

    def initialize(param_key)
      self.param_key = param_key
    end

    def matches?(request)
      if shipment = Shipment.where(id: request.parameters[param_key]).first
        shipment.regular_shipment?
      else
        # Fall back to `true` if we can't find the shipment.
        true
      end
    end
  end

  class FerryBookingConstraint
    attr_accessor :param_key

    def initialize(param_key)
      self.param_key = param_key
    end

    def matches?(request)
      if shipment = Shipment.where(id: request.parameters[param_key]).first
        shipment.ferry_booking_shipment?
      else
        # Fall back to `false` if we can't find the shipment.
        false
      end
    end
  end

  private_constant :RegularConstraint, :FerryBookingConstraint
end
