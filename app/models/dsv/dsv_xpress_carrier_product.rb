class DSVXpressCarrierProduct < DSVGenericCarrierProduct
  def service
    "Z09"
  end

  def zip_code_to_dsv_location_identifier(zip_code)
    if DSVAreas::SJAELLAND.include?(zip_code)
      "DKCPH"
    elsif DSVAreas::FYN.include?(zip_code)
      "DKODE"
    elsif DSVAreas::NORDJYLLAND.include?(zip_code)
      "DKAAL"
    elsif DSVAreas::MIDTJYLLAND_AREA_ZIP_CODES.include?(zip_code) 
      "DKBLL"
    end
  end

  def dsv_label_text
    "Xpress"
  end
end
