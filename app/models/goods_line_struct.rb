GoodsLineStruct = Struct.new(
  :quantity,
  :goods_identifier,
  :length,
  :width,
  :height,
  :weight,
  :volume_weight,
  :non_stackable,
) do
  def total_weight
    quantity * weight
  end

  def total_volume_weight
    if volume_weight
      quantity * volume_weight
    else
      0
    end
  end

  def non_stackable?
    non_stackable
  end
end
