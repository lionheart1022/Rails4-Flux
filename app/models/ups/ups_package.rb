class UPSPackage < Package
  SURCHARGE_MAPPING = {
    "additional_handling" => "UPSSurcharges::AdditionalHandling",

    # residential, remote_area, extended_area_delivery are also available as fee data
    # but they are not handled currently in the carrier feedback because of possible conflicts
    # with other parts of the price calculation.
  }

  def applicable_surcharge_types
    return [] if active_recording.nil? || active_recording.fee_data.nil?

    active_recording.fee_data.each_with_object([]) do |(status, fee_identifier), types|
      if status == "ok"
        type = SURCHARGE_MAPPING[fee_identifier]
        types << type if type
      end
    end
  end
end
