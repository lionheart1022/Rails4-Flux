class DSVRoadGroupageCarrierProduct < DSVGenericRoadCarrierProduct
  def service
    # TSR.
    # > ROAD
    # > 3 (groupage)
    "3"
  end

  def dsv_label_text
    "Road Groupage"
  end
end
