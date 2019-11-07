class ShipmentStatsManager
  MATCHING_EVENTS = [
    Shipment::Events::CREATE,
    Shipment::Events::WAITING_FOR_BOOKING,
    Shipment::Events::BOOKING_INITIATED,
    Shipment::Events::BOOK,
    Shipment::Events::AUTOBOOK,
    Shipment::Events::RETRY_AWB_DOCUMENT,
    Shipment::Events::RETRY_CONSIGNMENT_NOTE,
    Shipment::Events::AUTOBOOK_WITH_WARNINGS,
    Shipment::Events::BOOK_WITHOUT_AWB_DOCUMENT,
    Shipment::Events::FETCHING_AWB_DOCUMENT,
    Shipment::Events::BOOK_WITHOUT_CONSIGNMENT_NOTE,
    Shipment::Events::REPORT_AUTOBOOK_CONSIGNMENT_NOTE_PROBLEM,
    Shipment::Events::FETCHING_CONSIGNMENT_NOTE,
    Shipment::Events::SHIP,
    Shipment::Events::DELIVERED_AT_DESTINATION,
    Shipment::Events::CANCEL,
    Shipment::Events::BOOKING_FAIL,
    Shipment::Events::REPORT_AUTOBOOK_AWB_PROBLEM,
    Shipment::Events::REPORT_AUTOBOOK_PROBLEM,
    Shipment::Events::REPORT_PROBLEM,
    Shipment::Events::ADD_PRICE,
    Shipment::Events::SET_SALES_PRICE,
    Shipment::ContextEvents::COMPANY_UPDATE,
    Shipment::Events::UPDATE_SHIPMENT_PRICE,
    Shipment::ContextEvents::RETRY_AND_AUTOBOOK,
    Shipment::Events::RETRY,
    Shipment::Events::CREATE_OR_UPDATE_SHIPMENT_NOTE,
  ]

  class << self
    def handle_event(event: nil, event_arguments: nil)
      case event
      when *MATCHING_EVENTS
        shipment = Shipment.find(event_arguments[:shipment_id])
        AggregateShipmentStatistic.register_changed_shipment(shipment)
      end
    end
  end
end
