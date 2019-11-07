class Companies::Prices::SetSalesPrice < ApplicationInteractor

  def initialize(company_id: nil, shipment_id: nil, line_price_id: nil, price_data: nil)
    @company_id     = company_id
    @shipment_id    = shipment_id
    @line_price_id  = line_price_id
    @price_data     = price_data

    return self
  end

  def run
    AdvancedPrice.transaction do
      @shipment = Shipment.find_company_shipment(company_id: @company_id, shipment_id: @shipment_id)

      is_setting_on_customer = @shipment.company_id == @company_id
      is_setting_on_customer ? set_customer_price : set_company_price

      EventManager.handle_event(event: Shipment::Events::SET_SALES_PRICE, event_arguments: { shipment_id: @shipment_id })

      return InteractorResult.new(shipment: @shipment)
    end
  end

  def set_customer_price
    buyer = Shipment.find_company_or_customer_payer(current_company_id: @company_id, shipment_id: @shipment_id)
    buyer_type = buyer.class.to_s
    advanced_price = AdvancedPrice.find_seller_shipment_price(shipment_id: @shipment_id, seller_id: @company_id, seller_type: Company.to_s)
    advanced_price.buyer_id = buyer.id
    advanced_price.buyer_type = buyer.class


    line_item                    = advanced_price.advanced_price_line_items.where(id: @line_price_id).first
    line_item.cost_price_amount  = @price_data[:cost_price_amount] if @price_data[:cost_price_amount].present? && owns_product?
    line_item.sales_price_amount = @price_data[:sales_price_amount] if @price_data[:sales_price_amount]
    line_item.description        = @price_data[:description] if @price_data[:description]
    advanced_price.sales_price_currency = @price_data[:sales_price_currency] if @price_data[:sales_price_currency]

    line_item.save!
    advanced_price.save!
  end

  def set_company_price
    buyer = Shipment.find_company_or_customer_payer(current_company_id: @company_id, shipment_id: @shipment_id)
    buyer_type = buyer.class.to_s
    advanced_price = AdvancedPrice.find_seller_shipment_price(shipment_id: @shipment_id, seller_id: @company_id, seller_type: Company.to_s)

    advanced_price.buyer_id = buyer.id
    advanced_price.buyer_type = buyer.class

    line_item = advanced_price.advanced_price_line_items.where(id: @line_price_id).first

    line_item.cost_price_amount  = @price_data[:cost_price_amount] if @price_data[:cost_price_amount].present? && owns_product?

    line_item.sales_price_amount = @price_data[:sales_price_amount] if @price_data[:sales_price_amount]
    line_item.description        = @price_data[:description] if @price_data[:description]
    advanced_price.sales_price_currency = @price_data[:sales_price_currency] if @price_data[:sales_price_currency]

    line_item.save!
    advanced_price.save!

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

    # customer_line_item = advanced_price.advanced_price_line_items.where(description: line_item.description)

    line_item = AdvancedPriceLineItem.create_line_item(
      advanced_price_id: advanced_price.id,
      description: @price_data[:description],
      cost_price_amount: @price_data[:sales_price_amount],
    )
    advanced_price.save!
  end

  def owns_product?
    owner_company = @shipment.carrier_product.first_unlocked_product_in_owner_chain.company
    root = owner_company.id == @company_id ? true : false
  end

end
