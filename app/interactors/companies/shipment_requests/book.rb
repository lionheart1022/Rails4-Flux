class Companies::ShipmentRequests::Book < ApplicationInteractor

  def initialize(company_id: nil, shipment_request_id: nil)
    @company_id          = company_id
    @shipment_request_id = shipment_request_id

    self
  end

  def run
    find_shipment

    ShipmentRequest.transaction do
      book_shipment
      update_request
      send_email

      ShipmentStatsManager.handle_event(event: Shipment::Events::BOOK, event_arguments: { shipment_id: @shipment.id })

      return InteractorResult.new(shipment: @shipment)
    end
  end

  private

    def find_shipment
      @shipment_request = ShipmentRequest
        .includes(:shipment)
        .find_company_shipment_request(company_id: @company_id, shipment_request_id: @shipment_request_id)

      @shipment = @shipment_request.shipment
    end

    def book_shipment
      @shipment.book
    end

    def update_request
      @shipment_request.book
    end

    def send_email
      ShipmentRequestNotificationManager.handle_event(@shipment_request, event: ShipmentRequest::Events::BOOK)
    end

end
