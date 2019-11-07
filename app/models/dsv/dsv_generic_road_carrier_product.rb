class DSVGenericRoadCarrierProduct < DSVGenericCarrierProduct
  def zip_code_to_dsv_location_identifier(zip_code)
    if ("0".."4999").include?(zip_code)
      "DKCPH"
    elsif ("5000".."9999").include?(zip_code)
      "DKHOR"
    end
  end
end
