class UPSSaverDomesticCarrierProduct < UPSSaverCarrierProduct
  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    # This product has been disabled as the parent saver product now also allows domestic shipments
    false
  end
end
