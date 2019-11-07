class ReportShipmentFilter < ActiveRecord::Base
  belongs_to :company, required: true
  belongs_to :customer_recording
  belongs_to :carrier

  def determine_shipment_ids
    filter =
      if customer_recording
        ShipmentFilter.new(customer_recording.shipment_filter_params)
      else
        ShipmentFilter.new(current_company: company, base_relation: Shipment.find_company_shipments(company_id: company_id))
      end

    filter.carrier_id = carrier_id
    filter.report_inclusion = report_inclusion
    filter.pricing_status = pricing_status
    filter.state = shipment_state
    filter.shipping_start_date = start_date
    filter.shipping_end_date = end_date

    filter.perform!

    filter
      .shipments
      .order(shipping_date: :desc, id: :desc)
      .pluck(:id)
  end
end
