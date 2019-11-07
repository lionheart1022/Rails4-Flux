class Customers::ShipmentRequests::Update < ApplicationInteractor

  def initialize(company_id: nil, customer_id: nil, shipment_request_id: nil, data: nil)
    @company_id = company_id
    @customer_id = customer_id
    @shipment_request_id = shipment_request_id
    @data = data

    self
  end

  def run
    ShipmentRequest.transaction do
      find_shipment_request
      update_shipment_request
      create_event
    end

    return InteractorResult.new(shipment_request: @shipment_request)
  end

  private

    def find_shipment_request
      @shipment_request = ShipmentRequest.find_customer_shipment_request(company_id: @company_id, customer_id: @customer_id, shipment_request_id: @shipment_request_id)
    end

    def update_shipment_request
      @shipment_request.update_attributes!(@data)
    end

    def create_event
      state = @data[:state]
      case state
      when ShipmentRequest::States::ACCEPTED
        @shipment_request.accept
        ShipmentRequestNotificationManager.handle_event(@shipment_request, event: ShipmentRequest::Events::ACCEPT)
      when ShipmentRequest::States::DECLINED
        @shipment_request.decline
        ShipmentRequestNotificationManager.handle_event(@shipment_request, event: ShipmentRequest::Events::DECLINE)
      when ShipmentRequest::States::CANCELED
        @shipment_request.cancel
        ShipmentRequestNotificationManager.handle_event(@shipment_request, event: ShipmentRequest::ContextEvents::CUSTOMER_CANCEL)
      else
        raise ArgumentError, "Unhandled customer shipment request state change event: #{state}"
      end
    end

end
