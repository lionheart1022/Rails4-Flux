class ShipmentExportManager
  EVENT_TO_NEW_STATE_MAPPING = {
    Shipment::Events::CREATE => Shipment::States::CREATED,
    Shipment::Events::WAITING_FOR_BOOKING => Shipment::States::WAITING_FOR_BOOKING,
    Shipment::Events::BOOKING_INITIATED => Shipment::States::BOOKING_INITIATED,
    Shipment::Events::BOOK => Shipment::States::BOOKED,
    Shipment::Events::AUTOBOOK => Shipment::States::BOOKED,
    Shipment::Events::RETRY_AWB_DOCUMENT => Shipment::States::BOOKED,
    Shipment::Events::RETRY_CONSIGNMENT_NOTE => Shipment::States::BOOKED,
    Shipment::Events::AUTOBOOK_WITH_WARNINGS => Shipment::States::BOOKED,
    Shipment::Events::BOOK_WITHOUT_AWB_DOCUMENT => Shipment::States::BOOKED_WAITING_AWB_DOCUMENT,
    Shipment::Events::FETCHING_AWB_DOCUMENT => Shipment::States::BOOKED_AWB_IN_PROGRESS,
    Shipment::Events::BOOK_WITHOUT_CONSIGNMENT_NOTE => Shipment::States::BOOKED_WAITING_CONSIGNMENT_NOTE,
    Shipment::Events::REPORT_AUTOBOOK_CONSIGNMENT_NOTE_PROBLEM => Shipment::States::BOOKED_WAITING_CONSIGNMENT_NOTE,
    Shipment::Events::FETCHING_CONSIGNMENT_NOTE => Shipment::States::BOOKED_CONSIGNMENT_NOTE_IN_PROGRESS,
    Shipment::Events::SHIP => Shipment::States::IN_TRANSIT,
    Shipment::Events::DELIVERED_AT_DESTINATION => Shipment::States::DELIVERED_AT_DESTINATION,
    Shipment::Events::CANCEL => Shipment::States::CANCELLED,
    Shipment::ContextEvents::CUSTOMER_CANCEL => Shipment::States::CANCELLED,
    Shipment::Events::BOOKING_FAIL => Shipment::States::BOOKING_FAILED,
    Shipment::Events::REPORT_AUTOBOOK_AWB_PROBLEM => Shipment::States::BOOKING_FAILED,
    Shipment::Events::REPORT_AUTOBOOK_PROBLEM => Shipment::States::BOOKING_FAILED,
    Shipment::Events::REPORT_PROBLEM => Shipment::States::PROBLEM,
  }

  MATCHING_EVENTS = [
    Shipment::Events::ADD_PRICE,
    Shipment::Events::SET_SALES_PRICE,
    Shipment::ContextEvents::COMPANY_UPDATE,
    Shipment::Events::UPDATE_SHIPMENT_PRICE,
    Shipment::ContextEvents::RETRY_AND_AUTOBOOK,
    Shipment::Events::RETRY,
    Shipment::Events::CREATE_OR_UPDATE_SHIPMENT_NOTE,
  ] + EVENT_TO_NEW_STATE_MAPPING.keys

  class << self
    def handle_event(event: nil, event_arguments: nil)
      case event
      when *MATCHING_EVENTS
        shipment = Shipment.find(event_arguments[:shipment_id])
        next_state = EVENT_TO_NEW_STATE_MAPPING.fetch(event, shipment.state)
        ShipmentExportSetting.handle_export_triggers(shipment: shipment, new_state: next_state)
      end
    end
  end
end
