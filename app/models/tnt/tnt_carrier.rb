class TNTCarrier < Carrier
  def carrier_specific_surcharges
    build_surcharges_from_config(:tnt)
  end
end
