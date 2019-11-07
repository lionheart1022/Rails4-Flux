class Companies::ShipmentRequests::Update < ApplicationInteractor

  def initialize(company_id: nil, shipment_request_id: nil, data: nil)
    @company_id = company_id
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
      @shipment_request = ShipmentRequest.find_company_shipment_request(company_id: @company_id, shipment_request_id: @shipment_request_id)
    end

    def update_shipment_request
      @shipment_request.update_attributes!(@data)
    end

    def create_event
      state = @data[:state]
      case state
      when ShipmentRequest::States::PROPOSED
        @shipment_request.propose
        ShipmentRequestNotificationManager.handle_event(@shipment_request, event: ShipmentRequest::Events::PROPOSE)
      when ShipmentRequest::States::BOOKED
        @shipment_request.book
        ShipmentRequestNotificationManager.handle_event(@shipment_request, event: ShipmentRequest::Events::BOOK)
      when ShipmentRequest::States::CANCELED
        @shipment_request.cancel
        ShipmentRequestNotificationManager.handle_event(@shipment_request, event: ShipmentRequest::ContextEvents::COMPANY_CANCEL)
      else
        raise ArgumentError, "Unhandled company shipment request state change event: #{state}"
      end
    end

end
