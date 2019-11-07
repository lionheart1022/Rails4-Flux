class UnifaunGroupageNorwayCarrierProduct < UnifaunGenericCarrierProduct
  def postnord_sender_partners
    [
      {
        id: "DTPG",
        customer_number: get_credentials[:customer_number],
      }
    ]
  end

  def service
    UnifaunServices::GROUPAGE_NORWAY
  end
end
