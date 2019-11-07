class DHLExpressImportCarrierProduct < DHLGenericCarrierProduct

  def import?
    true
  end

  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    import
  end

  def service(recipient: nil, sender: nil)
    express_default_product_code(recipient: recipient, sender: sender)
  end

end
