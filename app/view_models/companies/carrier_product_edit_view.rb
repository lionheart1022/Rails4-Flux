class Companies::CarrierProductEditView
  attr_accessor :form_object
  attr_reader :carrier, :carrier_product

  def carrier_product=(carrier_product)
    @carrier_product = carrier_product
    @carrier = carrier_product ? carrier_product.carrier : nil
  end
end
