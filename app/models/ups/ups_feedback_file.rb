class UPSFeedbackFile < CarrierFeedbackFile
  def header_label
    "UPS"
  end

  def file_contents_as_latin1
    latin1_contents = file_contents.dup
    latin1_contents.force_encoding("ISO-8859-1")
    latin1_contents
  end

  def parse_file_and_persist_updates!
    parse_result = UPSBillingXMLFile.parse_xml(file_contents_as_latin1)

    parse_result.each do |_, shipment_entry|
      shipment_entry[:packages].each do |_, package_entry|
        if shipment_entry[:shipment_reference_1].to_s.start_with?("CF-")
          # Great!
          # The shipments with a reference prefixed with CF- will very likely originate from CargoFlux.
          # The other shipments are ignored.
        else
          next
        end

        if same_account_numbers?(shipment_entry[:account_number], configuration.account_details["account_number"])
          # Great!
        else
          next
        end

        matching_packages = UPSPackage.where(unique_identifier: package_entry[:pkg_tracking_number]).order(id: :desc).select do |package|
          same_account_numbers?(package.shipment.carrier_product.get_credentials[:account], shipment_entry[:account_number])
        end

        package_recording = nil
        package = matching_packages.first

        if package
          package_recording_fee_data = package_entry[:pkg_surcharges]
          package_recording = PackageRecording.create!(package: package, weight_value: package_entry[:pkg_actual_weight], weight_unit: "kg", fee_data: package_recording_fee_data)
        end

        package_update_metadata = {
          "account_number" => package_entry[:account_number],
          "actual_weight" => package_entry[:pkg_actual_weight],
          "actual_weight_unit" => package_entry[:pkg_actual_weight_unit],
        }

        PackageUpdate.create!(feedback_file: self, package_recording: package_recording, package: package, metadata: package_update_metadata)
      end
    end
  end

  private

  def same_account_numbers?(n1, n2)
    if n1.is_a?(String) && n2.is_a?(String)
      normalize_account_number(n1) == normalize_account_number(n2)
    end
  end

  def normalize_account_number(n)
    n.rjust(10, '0')
  end
end
