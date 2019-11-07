class PacsoftPostDkPrivatpakkerNordenMedOmdelingCarrierProduct < PacsoftGenericCarrierProduct

  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    is_domestic = is_domestic_shipment?(sender_country_code: sender_country_code, destination_country_code: destination_country_code)
    is_import   = import

    return !is_import && is_domestic
  end

  def supports_auto_book_delivery?
    true
  end

  def service
    return PacsoftShipperLib::ServiceCodes::PostDk::PRIVATPAKKER_NORDEN_MED_OMDELING
  end

  def partner
    return PacsoftShipperLib::PartnerCodes::PDK
  end
end
