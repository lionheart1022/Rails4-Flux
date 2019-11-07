class DSVDanpackCarrierProduct < DSVGenericCarrierProduct
  def service
    "Z02"
  end

  def zip_code_to_dsv_location_identifier(zip_code)
    if DSVAreas::SJAELLAND.include?(zip_code)
      "DPCPH"
    elsif DSVAreas::FYN.include?(zip_code)
      "DPODE"
    elsif DSVAreas::NORDJYLLAND.include?(zip_code)
      "DPAAL"
    elsif DSVAreas::MIDTJYLLAND.include?(zip_code) 
      "DPBLL"
    end
  end

  def dsv_label_text
    "Danpack"
  end
end
