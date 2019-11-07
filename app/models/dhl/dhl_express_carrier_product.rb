class DHLExpressCarrierProduct < DHLGenericCarrierProduct

  def service(recipient: nil, sender: nil)
    express_default_product_code(recipient: recipient, sender: sender)
  end

end
