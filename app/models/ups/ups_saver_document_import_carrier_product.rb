class UPSSaverDocumentImportCarrierProduct < UPSGenericCarrierProduct
  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    import && is_international_shipment?(sender_country_code: sender_country_code, destination_country_code: destination_country_code)
  end

  def import?
    true
  end

  def service
    UPSShipperLib::ServiceCodes::International::SAVER
  end

  def ups_documents_only?
    true
  end
end
