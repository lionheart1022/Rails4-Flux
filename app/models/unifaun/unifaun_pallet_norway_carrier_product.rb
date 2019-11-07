class UnifaunPalletNorwayCarrierProduct < UnifaunGenericCarrierProduct
  def postnord_pallet?
    true
  end

  def postnord_sender_partners
    [
      {
        id: "DTPG",
        customer_number: get_credentials[:customer_number],
      }
    ]
  end

  def service
    UnifaunServices::PALLET_NORWAY
  end
end
