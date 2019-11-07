class Companies::Prices::AddPrice < ApplicationInteractor

  def initialize(company_id: nil, shipment_id: nil, price_data: nil)
    @company_id     = company_id
    @shipment_id    = shipment_id
    @price_data     = price_data

    return self
  end

  def run
    AdvancedPrice.transaction do
      shipment = Shipment.find_company_shipment(company_id: @company_id, shipment_id: @shipment_id)

      is_setting_on_customer = shipment.company_id == @company_id
      is_setting_on_customer ? set_customer_price : set_company_price

      EventManager.handle_event(event: Shipment::Events::ADD_PRICE, event_arguments: { shipment_id: @shipment_id })
    end
  end

  def set_customer_price
    buyer = Shipment.find_company_or_customer_payer(current_company_id: @company_id, shipment_id: @shipment_id)
    advanced_price = AdvancedPrice.find_seller_shipment_price(shipment_id: @shipment_id, seller_id: @company_id, seller_type: Company.to_s)

    advanced_price = AdvancedPrice.upsert_advanced_price(
      seller_id: @company_id,
      seller_type: Company.to_s,
      buyer_id: buyer.id,
      buyer_type: buyer.class.to_s,
      shipment_id: @shipment_id,
      price_type: AdvancedPrice::Types::MANUAL,
      cost_price_currency: @price_data[:cost_price_currency],
      sales_price_currency: @price_data[:sales_price_currency],
      line_items: (advanced_price && advanced_price.advanced_price_line_items) || [],
    )

    line_item = AdvancedPriceLineItem.create_line_item(
      advanced_price_id: advanced_price.id,
      description: @price_data[:description],
      cost_price_amount: @price_data[:cost_price_amount] || 0,
      sales_price_amount: @price_data[:sales_price_amount],
      price_type: @price_data[:price_type]
    )
  end

  def set_company_price
    buyer = Shipment.find_company_or_customer_payer(current_company_id: @company_id, shipment_id: @shipment_id)
    buyer_type = buyer.class.to_s
    advanced_price = AdvancedPrice.find_seller_shipment_price(shipment_id: @shipment_id, seller_id: @company_id, seller_type: Company.to_s)

    advanced_price = AdvancedPrice.upsert_advanced_price(
      seller_id: @company_id,
      seller_type: Company.to_s,
      buyer_id: buyer.id,
      buyer_type: buyer.class.to_s,
      shipment_id: @shipment_id,
      price_type: AdvancedPrice::Types::MANUAL,
      cost_price_currency: @price_data[:cost_price_currency],
      sales_price_currency: @price_data[:sales_price_currency],
      line_items: (advanced_price && advanced_price.advanced_price_line_items) || [],
    )

    line_item = AdvancedPriceLineItem.create_line_item(
      advanced_price_id: advanced_price.id,
      description: @price_data[:description],
      cost_price_amount: @price_data[:cost_price_amount] || 0,
      sales_price_amount: @price_data[:sales_price_amount],
      price_type: @price_data[:price_type]
    )

    # set cost price for customer company

    advanced_price = AdvancedPrice.find_seller_shipment_price(shipment_id: @shipment_id, seller_id: buyer.id, seller_type: buyer_type)

    if advanced_price.blank?
      price_data = {
        seller_id: buyer.id,
        seller_type: buyer_type,
        shipment_id: @shipment_id,
        price_type: AdvancedPrice::Types::MANUAL,
        cost_price_currency: @price_data[:sales_price_currency],
      }

      advanced_price = AdvancedPrice.create_advanced_price(price_data)
    else
      advanced_price.cost_price_currency = @price_data[:sales_price_currency] if @price_data[:sales_price_currency]
    end

    line_item = AdvancedPriceLineItem.create_line_item(
      advanced_price_id: advanced_price.id,
      description: @price_data[:description],
      cost_price_amount: @price_data[:sales_price_amount],
      price_type: @price_data[:price_type]
    )

    advanced_price.save!
  end

  def owns_product?(shipment)
    owner_company = shipment.carrier_product.first_unlocked_product_in_owner_chain.company
    root = owner_company.id == @company_id ? true : false
  end

end
