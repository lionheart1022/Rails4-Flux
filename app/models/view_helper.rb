module ViewHelper

  def self.get_group_filter_sort_values(company_id: nil, group_type: nil, group_data: nil, filter_state: nil, filter_customer_type: nil, filter_customer_id: nil, filter_company_id: nil, filter_carrier_id: nil, filter_not_in_manifest: nil, filter_not_in_report: nil, filter_has_been_booked: nil, sort: nil, filter_not_canceled: nil, filter_has_been_booked_or_in_state: nil, active_or_in_state: nil, filter_range_start: nil, filter_range_end: nil)
    filters = []
    filters << GroupSortFilter::Filter.new(filter: CargofluxConstants::Filter::STATE,           filter_value: filter_state)                                                   if (filter_state && filter_state != '')
    filters << GroupSortFilter::Filter.new(filter: CargofluxConstants::Filter::CUSTOMER_ID,     filter_value: filter_customer_id)                                             if (filter_customer_id && filter_customer_id != '')
    filters << GroupSortFilter::Filter.new(filter: CargofluxConstants::Filter::CARRIER_ID,      filter_value: filter_carrier_id)                                              if (filter_carrier_id && filter_carrier_id != '')
    filters << GroupSortFilter::Filter.new(filter: CargofluxConstants::Filter::NOT_IN_MANIFEST, filter_value: filter_not_in_manifest)                                         if (filter_not_in_manifest && filter_not_in_manifest != '')
    filters << GroupSortFilter::Filter.new(filter: CargofluxConstants::Filter::NOT_IN_REPORT,   filter_value: company_id)                                                     if (filter_not_in_report && filter_not_in_report != '')
    filters << GroupSortFilter::Filter.new(filter: CargofluxConstants::Filter::HAS_BEEN_BOOKED, filter_value: filter_has_been_booked)                                         if (filter_has_been_booked && filter_has_been_booked != '')
    filters << GroupSortFilter::Filter.new(filter: CargofluxConstants::Filter::NOT_CANCELED,    filter_value: filter_not_canceled)                                            if (filter_not_canceled && filter_not_canceled != '')
    filters << GroupSortFilter::Filter.new(filter: CargofluxConstants::Filter::HAS_BEEN_BOOKED_OR_IN_STATE,    filter_value: filter_has_been_booked_or_in_state)              if (filter_has_been_booked_or_in_state && filter_has_been_booked_or_in_state != '')
    filters << GroupSortFilter::Filter.new(filter: CargofluxConstants::Filter::ACTIVE_OR_IN_STATE, filter_value: active_or_in_state)                                          if (active_or_in_state && active_or_in_state != '')
    filters << GroupSortFilter::Filter.new(filter: CargofluxConstants::Filter::CUSTOMER_TYPE,   filter_value: {company_id: company_id, customer_type: filter_customer_type})  if (filter_customer_type && filter_customer_type != '')
    filters << GroupSortFilter::Filter.new(filter: CargofluxConstants::Filter::COMPANY_ID,      filter_value: filter_company_id)                                              if (filter_company_id && filter_company_id != '')
    filters << GroupSortFilter::Filter.new(filter: CargofluxConstants::Filter::RANGE_START,     filter_value: filter_range_start)                                             if (filter_range_start && filter_range_start != '')
    filters << GroupSortFilter::Filter.new(filter: CargofluxConstants::Filter::RANGE_END,       filter_value: filter_range_end)                                               if (filter_range_end && filter_range_end != '')

    # sorting
    sorting = sort

    # grouping
    grouping = GroupSortFilter::Group.new(type: group_type, data: group_data)
    return filters, grouping, sorting
  end

  def self.group_name(name: nil, reference: nil)
    if reference == Pickup::States
      ViewHelper::Pickups.state_name(name)
    elsif reference == Shipment::States
      ViewHelper::Shipments.state_name(name)
    elsif reference == CarrierProductAutobookRequest::States
      ViewHelper::CarrierProductAutobookRequests.state_name(name)
    else
      name
    end
  end

  module Shipments

    def self.customer_email_shipment_url_with_common_or_company_domain(shipment: nil, company: nil)
      CurrentContextUrls.new(company: company, customer: shipment.customer).customers_shipment_url(shipment)
    end

    def self.company_email_shipment_url_with_common_or_company_domain(shipment: nil, company: nil)
      CurrentContextUrls.new(company: company).companies_shipment_url(shipment)
    end

    def self.state_name(state)
      case state
        when Shipment::States::CREATED
          "Created"
        when Shipment::States::BOOKING_FAILED
          "Booking failed"
        when Shipment::States::WAITING_FOR_BOOKING
          "Waiting for booking"
        when Shipment::States::BOOKING_INITIATED
          "Booking initiated"
        when Shipment::States::BOOKED_WAITING_AWB_DOCUMENT
          "Booked - waiting for AWB document"
        when Shipment::States::BOOKED_AWB_IN_PROGRESS
          "Booked - fetching AWB document"
        when Shipment::States::BOOKED_WAITING_CONSIGNMENT_NOTE
          "Booked - waiting for consignment note"
        when Shipment::States::BOOKED_CONSIGNMENT_NOTE_IN_PROGRESS
          "Booked - fetching consignment note"
        when Shipment::States::BOOKED
          "Booked"
        when Shipment::States::IN_TRANSIT
          "In transit"
        when Shipment::States::DELIVERED_AT_DESTINATION
          "Delivered"
        when Shipment::States::CANCELLED
          "Cancelled"
        when Shipment::States::PROBLEM
          "Problem"
        when Shipment::States::REQUEST
          "Requested"
      end
    end

    def self.event_name(event)
      case event
        when Shipment::Events::CREATE
          "Created"
        when Shipment::Events::BOOKING_FAIL
          "Booking failed"
        when Shipment::Events::RETRY
          "Retrying"
        when Shipment::Events::WAITING_FOR_BOOKING
          "Waiting for booking"
        when Shipment::Events::BOOKING_INITIATED
          "Booking initiated"
        when Shipment::Events::BOOK_WITHOUT_AWB_DOCUMENT
          "Booked - waiting for AWB document"
        when Shipment::Events::FETCHING_AWB_DOCUMENT
          "Fetching AWB document"
        when Shipment::Events::BOOK_WITHOUT_CONSIGNMENT_NOTE
          "Booked - waiting for consignment note"
        when Shipment::Events::FETCHING_CONSIGNMENT_NOTE
          "Fetching consignment note"
        when Shipment::Events::BOOK
          "Booked"
        when Shipment::Events::SHIP
          "Shipped"
        when Shipment::Events::REPORT_PROBLEM
          "Problem reported"
        when Shipment::Events::DELIVERED_AT_DESTINATION
          "Delivered"
        when Shipment::Events::CANCEL
          "Cancelled"
        when Shipment::Events::COMMENT
          "Commented"
        when Shipment::Events::INFO
          "Info"
        when Shipment::Events::ASSET_AWB_UPLOADED
          "AWB document added"
        when Shipment::Events::ASSET_INVOICE_UPLOADED
          "Invoice document added"
        when Shipment::Events::ASSET_CONSIGNMENT_NOTE_UPLOADED
          "Consignment note added"
        when Shipment::Events::ASSET_OTHER_UPLOADED
          "File added"
      end
    end

    def self.states_for_select
      [
        ["Created", Shipment::States::CREATED],
        ["Booked", Shipment::States::BOOKED],
        ["In transit", Shipment::States::IN_TRANSIT],
        ["Delivered at destination", Shipment::States::DELIVERED_AT_DESTINATION],
        ["Problem", Shipment::States::PROBLEM],
        ["Cancelled", Shipment::States::CANCELLED]
      ]
    end
  end

  module Pickups

    def self.customer_email_pickup_url_with_common_or_company_domain(pickup: nil, company: nil)
      CurrentContextUrls.new(company: company, customer: pickup.customer).customers_pickup_url(pickup)
    end

    def self.company_email_pickup_url_with_common_or_company_domain(pickup: nil, company: nil)
      CurrentContextUrls.new(company: company).companies_pickup_url(pickup)
    end

    def self.state_name(state)
      case state
        when Pickup::States::CREATED
          "Created"
        when Pickup::States::BOOKED
          "Booked"
        when Pickup::States::PICKED_UP
          "Picked up"
        when Pickup::States::CANCELLED
          "Cancelled"
        when Pickup::States::PROBLEM
          "Problem"
      end
    end

    def self.event_name(event)
      case event
        when Pickup::Events::CREATE
          "Created"
        when Pickup::Events::BOOK
          "Booked"
        when Pickup::Events::PICKUP
          "Picked up"
        when Pickup::Events::REPORT_PROBLEM
          "Problem reported"
        when Pickup::Events::CANCEL
          "Cancelled"
        when Pickup::Events::COMMENT
          "Commented"
      end
    end

    def self.states_for_select
      [
        ["Created", Pickup::States::CREATED],
        ["Booked", Pickup::States::BOOKED],
        ["Picked up", Pickup::States::PICKED_UP],
        ["Problem", Pickup::States::PROBLEM],
        ["Cancelled", Pickup::States::CANCELLED]
      ]
    end

  end

  module CarrierProductAutobookRequests

    def self.state_name(state)
      case state
        when CarrierProductAutobookRequest::States::CREATED
          "Created"
        when CarrierProductAutobookRequest::States::WAITING
          "Waiting"
        when CarrierProductAutobookRequest::States::IN_PROGRESS
          "In progress"
        when CarrierProductAutobookRequest::States::ERROR
          "Error"
        when CarrierProductAutobookRequest::States::COMPLETED
          "Completed"
      end
    end
  end

  module ShipmentRequests

    def self.customer_email_shipment_request_url_with_common_or_company_domain(shipment_request: nil, company: nil)
      CurrentContextUrls.new(company: company, customer: shipment_request.shipment.customer).customers_shipment_request_url(shipment_request)
    end

    def self.company_email_shipment_request_url_with_common_or_company_domain(shipment_request: nil, company: nil)
      CurrentContextUrls.new(company: company).companies_shipment_request_url(shipment_request)
    end

    def self.states_for_select
      [
        ["Created", ShipmentRequest::States::CREATED],
        ["Proposed", ShipmentRequest::States::PROPOSED],
        ["Accepted", ShipmentRequest::States::ACCEPTED],
        ["Booked", ShipmentRequest::States::BOOKED],
        ["Declined", ShipmentRequest::States::DECLINED]
      ]
    end

    def self.state_name(state)
      case state
        when ShipmentRequest::States::CREATED
          "Created"
        when ShipmentRequest::States::PROPOSED
          "Proposed"
        when ShipmentRequest::States::ACCEPTED
          "Accepted"
        when ShipmentRequest::States::BOOKED
          "Booked"
        when ShipmentRequest::States::DECLINED
          "Declined"
        when ShipmentRequest::States::CANCELED
          "Canceled"
      end
    end

    def self.event_name(event)
      case event
        when ShipmentRequest::Events::CREATE
          "Created"
        when ShipmentRequest::Events::PROPOSE
          "Proposed"
        when ShipmentRequest::Events::ACCEPT
          "Accepted"
        when ShipmentRequest::Events::BOOK
          "Booked"
        when ShipmentRequest::Events::DECLINE
          "Declined"
        when ShipmentRequest::Events::CANCEL
          "Canceled"
      end
    end

  end

end
