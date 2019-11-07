class GLSPrivateCarrierProduct < GLSGenericCarrierProduct
  def gls_is_private_service?
    true
  end

  def supports_delivery_instructions?
    true
  end
end
