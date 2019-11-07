class DHLDangerousGoodsMapping
  class << self
    def new_from_shipment(shipment)
      o = new

      if shipment.dangerous_goods?
        o.predefined_option = shipment.dangerous_goods_predefined_option
      end

      o
    end
  end

  attr_accessor :predefined_option
  attr_reader :content_id, :special_service_code

  def perform_mapping!
    case predefined_option
    when "dry_ice"
      set_mapping!(901, "HC")
    when "lithium_ion_UN3481_PI966"
      set_mapping!(912, "HE")
    when "lithium_ion_UN3481_PI967"
      set_mapping!(913, "HE")
    when "lithium_metal_UN3091_PI969"
      set_mapping!(932, "HE")
    when "lithium_metal_UN3091_PI970"
      set_mapping!(933, "HE")
    else
      set_no_mapping!
    end
  end

  def found_mapping?
    content_id && special_service_code
  end

  private

  def set_mapping!(content_id, special_service_code)
    @content_id = content_id
    @special_service_code = special_service_code

    true
  end

  def set_no_mapping!
    set_mapping!(nil, nil)

    false
  end
end
