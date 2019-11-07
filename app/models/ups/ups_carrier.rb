class UPSCarrier < Carrier
  def carrier_specific_surcharges
    build_surcharges_from_config(:ups)
  end
end
