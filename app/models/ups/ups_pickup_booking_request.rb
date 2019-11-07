class UPSPickupBookingRequest < CarrierPickupRequest
  attr_accessor :credentials_mismatch
  alias_method :credentials_mismatch?, :credentials_mismatch

  validate :params_must_be_valid
  validate :http_request_object_must_be_valid

  def setup_params
    self.params = {}
    self.params["pieces"] = []
    self.params["credentials"] = nil

    shipments.each do |shipment|
      credentials = {
        "access_license_number" => shipment.carrier_product.get_credentials[:access_token],
        "username" => shipment.carrier_product.get_credentials[:company],
        "password" => shipment.carrier_product.get_credentials[:password],
      }

      # Beware that we are using the credentials from the first shipments carrier product.
      self.params["credentials"] ||= credentials
      self.credentials_mismatch = true if self.params["credentials"] != credentials

      self.params["pieces"] << {
        "service_code" => shipment.carrier_product.service,
        "quantity" => shipment.number_of_packages,
        "destination_country_code" => shipment.recipient.country_code,
      }
    end

    true
  end

  def matching_shipment_count
    shipments.count
  end

  def handle!
    return if handled?

    pickup_response = nil

    http_req = build_http_request_object

    begin
      pickup_response = http_req.book_pickup!
    rescue => e
      pickup.report_problem(comment: "Pickup could not be booked at UPS")
      ExceptionMonitoring.report!(e)
    else
      if pickup_response.success?
        pickup.book(comment: "Pickup successfully booked at UPS (pickup request number: #{pickup_response.pickup_request_number})")
      elsif pickup_response.error?
        pickup.report_problem(comment: pickup_response.error_message)
      end
    end

    touch(:handled_at)
  end

  private

  def params_must_be_valid
    if params.try(:[], "credentials").blank? || params.try(:[], "pieces").blank?
      errors.add(:base, "No shipments match the pickup")
    end

    if credentials_mismatch?
      errors.add(:base, "Cannot determine which UPS credentials to use")
    end
  end

  def http_request_object_must_be_valid
    return if matching_shipment_count == 0

    http_req = build_http_request_object

    begin
      http_req.validate!
    rescue UPSPickupHTTPRequest::UserValidationError => e
      errors.add(:base, e.message)
    end
  end

  def build_http_request_object
    raise "`pickup` needs to be set" if pickup.nil?

    http_req = UPSPickupHTTPRequest.new

    http_req.username = params.try(:[], "credentials").try(:[], "username")
    http_req.password = params.try(:[], "credentials").try(:[], "password")
    http_req.access_license_number = params.try(:[], "credentials").try(:[], "access_license_number")

    http_req.date_info = UPSPickupHTTPRequest::DateInfo.new(
      pickup_date: pickup.pickup_date,
      ready_time: pickup.from_time,
      close_time: pickup.to_time,
    )

    combined_address_line = [
      pickup.contact.address_line1,
      pickup.contact.address_line2,
      pickup.contact.address_line3,
    ].reject(&:blank?).join("; ")

    http_req.address = UPSPickupHTTPRequest::Address.new(
      company_name: pickup.contact.company_name,
      contact_name: pickup.contact.attention,
      address_line: combined_address_line,
      postal_code: pickup.contact.zip_code,
      city: pickup.contact.city,
      country_code: pickup.contact.country_code,
      state_province: pickup.contact.state_code,
      phone_number: pickup.contact.phone_number,
      pickup_point: pickup.description,
    )

    Array(params.try(:[], "pieces")).each do |piece_params|
      http_req.pieces << UPSPickupHTTPRequest::Piece.new(
        service_code: piece_params["service_code"],
        quantity: piece_params["quantity"],
        destination_country_code: piece_params["destination_country_code"],
      )
    end

    http_req
  end

  def shipments
    return Shipment.none if pickup.nil?

    Shipment
      .where(company_id: pickup.company_id, customer_id: pickup.customer_id)
      .where.not(state: [Shipment::States::DELIVERED_AT_DESTINATION, Shipment::States::CANCELLED, Shipment::States::REQUEST])
      .includes(:carrier_product)
      .joins(:carrier_product => :carrier)
      .where(carriers: { type: "UPSCarrier" })
      .where(shipping_date: pickup.pickup_date)
  end
end
