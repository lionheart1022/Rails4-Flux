class ShipmentGoods < ActiveRecord::Base
  belongs_to :shipment, required: true
  has_many :lines, class_name: "GoodsLine", foreign_key: "container_id"

  VOLUME_TYPES = %w(
    loading_meter
    volume_weight
  )

  validates :volume_type, presence: true, inclusion: { in: VOLUME_TYPES }
  validates :dimension_unit, presence: true, inclusion: { in: %w(cm) }
  validates :weight_unit, presence: true, inclusion: { in: %w(kg) }

  after_initialize do |record|
    record.dimension_unit ||= "cm"
    record.weight_unit ||= "kg"
  end

  def ordered_lines
    lines.order(:id)
  end

  def total_volume_weight
    lines.to_a.sum(&:total_volume_weight)
  end

  def total_weight
    lines.to_a.sum(&:total_weight)
  end

  def total_item_quantity
    lines.to_a.sum(&:quantity)
  end
end
