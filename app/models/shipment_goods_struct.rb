ShipmentGoodsStruct = Struct.new(
  :volume_type,
  :dimension_unit,
  :weight_unit,
  :lines,
) do
  def ordered_lines
    lines
  end

  def total_volume_weight
    lines.sum(&:total_volume_weight)
  end

  def total_weight
    lines.sum(&:total_weight)
  end

  def total_item_quantity
    lines.sum(&:quantity)
  end
end
