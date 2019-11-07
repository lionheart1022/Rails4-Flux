class GoodsLine < ActiveRecord::Base
  belongs_to :container, class_name: "ShipmentGoods"

  GOODS_IDENTIFIERS = %w(
    CLL
    PLL
    HPL
    QPL
  )

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :goods_identifier, presence: true, inclusion: { in: GOODS_IDENTIFIERS }

  after_initialize do |record|
    record.goods_identifier ||= "CLL"
  end

  alias_attribute :amount, :quantity

  def assign_volume_weight_via_carrier_product(carrier_product)
    package_dimension = PackageDimension.new(
      length: length,
      width: width,
      height: height,
      weight: weight,
    )

    self.volume_weight = carrier_product.applied_volume_calculation(dimension: package_dimension)
  end

  def weight=(value)
    write_attribute(:weight, value.to_s.gsub(',', '.'))
  end

  def total_weight
    if weight
      quantity * weight
    else
      0
    end
  end

  def total_volume_weight
    if volume_weight
      quantity * volume_weight
    else
      0
    end
  end
end
