class GLSCarrier < Carrier
  def supports_override_credentials?
    true
  end

  def override_credentials_class
    GLSCarrierProductCredential
  end

  def carrier_specific_surcharges
    build_surcharges_from_config(:gls)
  end
end
