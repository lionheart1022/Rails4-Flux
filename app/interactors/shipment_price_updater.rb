class ShipmentPriceUpdater
  attr_reader :shipment, :new_prices

  def initialize(shipment:, new_prices:)
    @shipment = shipment
    @new_prices = new_prices
  end

  def did_prices_change?
    return true if new_prices.size != shipment.advanced_prices.size

    shipment.advanced_prices.each do |existing_price|
      similar_new_price = new_prices.detect { |price| prices_are_similar?(existing_price, price) }

      if similar_new_price.nil?
        return true
      end

      if similar_new_price.total_automatic_sales_price_amount.round(2) != existing_price.total_automatic_sales_price_amount.round(2)
        return true
      end
    end

    false
  end

  def perform_update!
    ActiveRecord::Base.transaction do
      delete_prices_for_missing_links!
      only_keep_manual_line_items!
      add_new_prices!
    end

    true
  end

  private

  def delete_prices_for_missing_links!
    AdvancedPrice.where(shipment: shipment).each do |existing_price|
      similar_new_price = new_prices.detect { |price| prices_are_similar?(existing_price, price) }

      if similar_new_price.nil?
        # If we reach here it most likely means that the carrier product has been changed.
        # The effect of this that the the (seller, buyer) "links" in the product chain have changed.
        existing_price.advanced_price_line_items.delete_all(:delete_all)
        existing_price.destroy
      end
    end
  end

  def only_keep_manual_line_items!
    AdvancedPrice.where(shipment: shipment).each do |existing_price|
      line_items_to_keep = existing_price.advanced_price_line_items.where(price_type: AdvancedPriceLineItem::Types::MANUAL)
      line_items_to_delete = existing_price.advanced_price_line_items.where.not(id: line_items_to_keep.pluck(:id))
      line_items_to_delete.delete_all
    end
  end

  def add_new_prices!
    new_prices.each do |new_price|
      similar_existing_price = shipment.advanced_prices.detect { |price| prices_are_similar?(price, new_price) }

      if similar_existing_price
        similar_existing_price.advanced_price_line_items << new_price.advanced_price_line_items
      else
        shipment.advanced_prices << new_price
      end
    end
  end

  def prices_are_similar?(a, b)
    extract_link_related_data_from_price(a) == extract_link_related_data_from_price(b)
  end

  def extract_link_related_data_from_price(price)
    {
      seller_type: price.seller_type,
      seller_id: price.seller_id,
      buyer_type: price.buyer_type,
      buyer_id: price.buyer_id,
      cost_price_currency: price.cost_price_currency,
      sales_price_currency: price.sales_price_currency,
    }
  end
end
