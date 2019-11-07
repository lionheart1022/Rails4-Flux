class AdvancedPrice < ActiveRecord::Base
  belongs_to :shipment
  belongs_to :seller, polymorphic: true
  belongs_to :buyer, polymorphic: true
  has_many :advanced_price_line_items

  module Types
    AUTOMATIC = 'automatic'
    MANUAL    = 'manual'
  end

  module Descriptions
    MANUAL    = 'Manual Price'
  end

  class << self
    def new_advanced_price(seller_id: nil, seller_type: nil, buyer_id: nil, buyer_type: nil, shipment_id: nil, price_type: nil, cost_price_currency: nil, sales_price_currency: nil, line_items: [])
      advanced_price = self.new({
        seller_id:                  seller_id,
        seller_type:                seller_type,
        buyer_id:                   buyer_id,
        buyer_type:                 buyer_type,
        shipment_id:                shipment_id,
        price_type:                 price_type,
        cost_price_currency:        cost_price_currency,
        sales_price_currency:       sales_price_currency,
        advanced_price_line_items:  line_items,
      })
    end

    def create_advanced_price(seller_id: nil, seller_type: nil, buyer_id: nil, buyer_type: nil, shipment_id: nil, price_type: nil, cost_price_currency: nil, sales_price_currency: nil, line_items: [])
      advanced_price = new_advanced_price(seller_id: seller_id, seller_type: seller_type, buyer_id: buyer_id, buyer_type: buyer_type, shipment_id: shipment_id, price_type: price_type, cost_price_currency: cost_price_currency, sales_price_currency: sales_price_currency, line_items: line_items)
      advanced_price.save!

      return advanced_price
    end

    def update_advanced_price(seller_id: nil, seller_type: nil, buyer_id: nil, buyer_type: nil, shipment_id: nil, price_type: nil, cost_price_currency: nil, sales_price_currency: nil, line_items: [])
      price = self.find_seller_shipment_price(shipment_id: shipment_id, seller_id: seller_id, seller_type: seller_type)
      price.update_attributes!(
        cost_price_currency: cost_price_currency || price.cost_price_currency,
        sales_price_currency: sales_price_currency || price.sales_price_currency,
        advanced_price_line_items: line_items
      )

      return price
    end

    def upsert_advanced_price(seller_id: nil, seller_type: nil, buyer_id: nil, buyer_type: nil, shipment_id: nil, price_type: nil, cost_price_currency: nil, sales_price_currency: nil, line_items: [])
      price = self.find_seller_shipment_price(shipment_id: shipment_id, seller_id: seller_id, seller_type: seller_type)

      if price.present?
        self.update_advanced_price(seller_id: seller_id, seller_type: seller_type, buyer_id: buyer_id, buyer_type: buyer_type, shipment_id: shipment_id, price_type: price_type, cost_price_currency: cost_price_currency, sales_price_currency: sales_price_currency, line_items: line_items)
      else
        self.create_advanced_price(seller_id: seller_id, seller_type: seller_type, buyer_id: buyer_id, buyer_type: buyer_type, shipment_id: shipment_id, price_type: price_type, cost_price_currency: cost_price_currency, sales_price_currency: sales_price_currency, line_items: line_items)
      end
    end

    def upsert_manual_price_line_item(seller_id: nil, seller_type: nil, buyer_id: nil, buyer_type: nil, shipment_id: nil, description: nil, cost_price_currency: nil, sales_price_currency: nil, cost_price_amount: nil, sales_price_amount: nil)
      price = self.find_seller_shipment_price(shipment_id: shipment_id, seller_id: seller_id, seller_type: seller_type)
      manual_line_item = price.advanced_price_line_items.first

      manual_line_item.cost_price_currency = cost_price_currency if cost_price_currency
      manual_line_item.cost_price_currency = sales_price_currency if sales_price_currency
      manual_line_item.cost_price_currency = cost_price_amount if cost_price_amount
      manual_line_item.cost_price_currency = sales_price_amount if sales_price_amount

      manual_line_item.save!
    end

    # Finders

    def find_seller_shipment_price(shipment_id: nil, seller_id: nil, seller_type: nil)
      self.where(shipment_id: shipment_id, seller_id: seller_id, seller_type: seller_type).first
    end

    def find_buyer_shipment_price(shipment_id: nil, buyer_id: nil, buyer_type: nil)
      self.where(shipment_id: shipment_id, buyer_id: buyer_id, buyer_type: buyer_type).first
    end

  end

  def total_cost_price_amount
    total = 0
    self.advanced_price_line_items.each do |item|
      item.cost_price_amount.present? ? total += item.cost_price_amount : 0
    end

    return total
  end

  def total_sales_price_amount
    total = 0
    self.advanced_price_line_items.each do |item|
      item.sales_price_amount.present? ? total += item.sales_price_amount : 0
    end

    return total
  end

  def total_automatic_sales_price_amount
    total = 0
    self
      .advanced_price_line_items
      .select{ |line| line.automatic? }
      .each do |item|
        item.sales_price_amount.present? ? total += item.sales_price_amount : 0
      end

    return total
  end

  def total_profit_amount
    total = 0
    self.advanced_price_line_items.each do |item|
      item.profit_amount.present? ? total += item.profit_amount : return
    end

    return total
  end

  def customer?
    buyer.class == Customer
  end

  def company?
    buyer.class == Company
  end

  def automatic?
  	self.price_type == Types::AUTOMATIC
  end
end
