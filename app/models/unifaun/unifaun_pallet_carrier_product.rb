class UnifaunPalletCarrierProduct < UnifaunGenericCarrierProduct
  def postnord_pallet?
    true
  end

  def service
    UnifaunServices::PALLET
  end
end
