module CustomerRecordingHelper
  def build_path_for_customer_recording(customer_recording)
    if customer_recording.is_a?(::CustomerRecordings::Customer)
      companies_customer_path(customer_recording.recordable_id)
    elsif customer_recording.is_a?(::CustomerRecordings::CarrierProductCustomer)
      companies_carrier_product_customer_carrier_product_customer_carriers_path(customer_recording.recordable_id)
    end
  end
end
