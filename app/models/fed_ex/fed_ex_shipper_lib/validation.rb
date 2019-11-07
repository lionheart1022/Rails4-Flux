class FedExShipperLib
  class Validation
    attr_reader :sender, :recipient, :errors, :shipment

    def initialize(sender:, recipient:, shipment:)
      @sender    = sender
      @recipient = recipient
      @shipment  = shipment
    end

    def validate
      @errors = []

      validate_shipment_in_future(shipment.shipping_date)

      validate_length(shipment, :reference, 40)
      validate_length(shipment, :description, 60)

      [sender, recipient].each do |contact|
        validate_length(contact, :company_name, 35)
        validate_length(contact, :attention, 35)
        validate_length(contact, :address_line1, 35)
        validate_length(contact, :address_line2, 35)
        validate_length(contact, :city, 20)
      end

      self
    end

    def valid?
      errors.size <= 0
    end

    def invalid?
      !valid?
    end

    private

    def validate_length(contact, attribute, max_length)
      value = contact.public_send(attribute)

      if value.present? && value.length > max_length
        @errors << BookingLib::Errors::APIError.new(
          code: "CF-FedEx-#{contact.class.to_s.downcase}_#{attribute}-length",
          description: too_long_error_message(contact, attribute, max_length, value),
          severity: "Error"
        )
      end
    end

    def too_long_error_message(contact, attribute, max_length, value)
      "#{contact.class} #{translate(attribute)} cannot be longer than " +
        "#{max_length} characters (currently #{value.length} characters)"
    end

    def translate(attribute)
      attribute.to_s.gsub('_', ' ')
    end

    def validate_shipment_in_future(shipping_date)
      if shipping_date.present? && shipping_date < Date.today
        @errors << BookingLib::Errors::APIError.new(
          code: "CF-FedEx-shipment-in-the-past",
          description: "The shipping date cannot be in the past",
          severity: "Error"
        )
      end
    end
  end
end
