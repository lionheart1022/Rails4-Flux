class AdvancedPriceLineItem < ActiveRecord::Base
  belongs_to :advanced_price

  serialize :parameters, Hash

  module Types
    AUTOMATIC = 'automatic'
    MANUAL    = 'manual'
  end

  class << self

    # Creators
    #
    #

    def new_line_item(advanced_price_id: nil, description: '', cost_price_amount: nil, sales_price_amount: nil, times: 1, parameters: nil, price_type: nil)
      line_item = self.new({
        advanced_price_id:  advanced_price_id,
        description:        description,
        cost_price_amount:  cost_price_amount,
        sales_price_amount: sales_price_amount,
        times:              times,
        parameters:         parameters,
        price_type:               price_type
      })

      return line_item
    end

    def create_line_item(advanced_price_id: nil, description: '', cost_price_amount: nil, sales_price_amount: nil, times: 1, parameters: nil, price_type: nil)
      line_item = new_line_item(advanced_price_id: advanced_price_id, cost_price_amount: cost_price_amount, description: description, sales_price_amount: sales_price_amount, times: times, parameters: parameters, price_type: price_type)
      line_item.save!

      return line_item
    end

    # Finders
    #
    #

    def find_seller_shipment_price_line(advanced_price_line_id: nil, seller_id: nil, seller_type: nil)
      self.joins("LEFT JOIN advanced_prices ap ON ap.id = advanced_price_line_items.advanced_price_id")
        .where("ap.seller_id = ? AND ap.seller_type = ?", seller_id, seller_type)
        .where("advanced_price_line_items.id = ?", advanced_price_line_id)
        .first
    end
  end

  def profit_amount
    if self.sales_price_amount.present? && self.cost_price_amount.present?
      self.sales_price_amount - self.cost_price_amount
    else
      nil
    end
  end

  # Only shipment and fuel charges are applied margin
  #
  def should_apply_margin?
    return false if self.parameters.nil?
    self.parameters.keys.include?(:distance) || self.parameters.keys.include?(:pallets) || self.parameters.keys.include?(:weight) && !self.parameters.keys.include?(:per) || self.parameters.keys.include?(:percentage)
  end

  def automatic?
    self.price_type == Types::AUTOMATIC
  end

end
