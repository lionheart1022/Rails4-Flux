class ShipmentPriceCalculation
  class << self
    def calculate(*args)
      new(*args).calculate
    end
  end

  attr_accessor :company_id, :customer_id
  attr_accessor :carrier_product
  attr_accessor :sender_country_code, :sender_zip_code
  attr_accessor :recipient_country_code, :recipient_zip_code
  attr_accessor :shipping_date
  attr_accessor :package_dimensions
  attr_accessor :goods_lines
  attr_accessor :distance_in_kilometers
  attr_accessor :dangerous_goods
  attr_accessor :residential
  attr_accessor :carrier_surcharge_types

  def initialize(params = {})
    params.each do |attr, value|
      self.public_send("#{attr}=", value)
    end
  end

  def calculate
    @carrier_product_price = carrier_product.referenced_carrier_product_price if carrier_product.references_price_document?
    @carrier_product_price ||= carrier_product.carrier_product_price

    return [] unless @carrier_product_price.try(:successful?)

    chain_builder = ChainBuilder.new(carrier_product: carrier_product, company_id: company_id, customer_id: customer_id)
    chain = chain_builder.as_array

    # First we calculate the base price via the price document
    base_price = calculate_base_price
    return [] if base_price.blank?

    prices = []
    previous_price = base_price

    # And then we calculate the prices for the companies/customers in the chain
    chain.each do |link|
      next_price = calculate_next_price(link, previous_price)
      return prices if next_price.blank?

      previous_price = next_price
      prices << next_price
    end

    prices
  end

  private

  def calculate_base_price
    new_package_dimensions = PackageDimensionsBuilder.build_and_apply_volume_weight(carrier_product: carrier_product, package_dimensions: package_dimensions)

    price_document = price_document_with_configurable_surcharges
    cost_price_calculations = price_document.calculate_price_for_shipment(
      sender_country_code: sender_country_code,
      sender_zip_code: sender_zip_code,
      recipient_country_code: recipient_country_code,
      recipient_zip_code: recipient_zip_code,
      package_dimensions: new_package_dimensions,
      margin: nil,
      import: carrier_product.owner_carrier_product.import?,
      dangerous_goods: dangerous_goods,
      distance_in_kilometers: distance_in_kilometers,
    )

    return if cost_price_calculations.blank?

    cost_charges = cost_price_calculations.charges

    return if cost_charges.blank?

    selected_zone = cost_price_calculations.price_calculations.first.zone
    @selected_zone_index = price_document.zones.index do |zone|
      zone.name == selected_zone.name
    end

    line_items = cost_charges.map do |cost_charge|
      AdvancedPriceLineItem.new(
        description: cost_charge.name,
        cost_price_amount: 0,
        sales_price_amount: cost_charge.total,
        times: cost_charge.times,
        parameters: cost_charge.parameters,
        price_type: AdvancedPriceLineItem::Types::AUTOMATIC,
      )
    end

    AdvancedPrice.new(
      price_type: AdvancedPrice::Types::AUTOMATIC,
      cost_price_currency: price_document.currency,
      sales_price_currency: price_document.currency,
      advanced_price_line_items: line_items,
    )
  rescue => e
    ExceptionMonitoring.report!(e)
    nil
  end

  def calculate_next_price(link, previous_price)
    return if link.sales_price.blank? || link.sales_price.inactive?

    base_line_item = nil

    line_items = previous_price.advanced_price_line_items.map do |line_item|
      next_line_item =
        AdvancedPriceLineItem.new(
          description: line_item.description,
          cost_price_amount: line_item.sales_price_amount,
          sales_price_amount: line_item.sales_price_amount,
          times: line_item.times,
          parameters: line_item.parameters,
          price_type: line_item.price_type,
        )

      r = link.sales_price.conditionally_apply_margin_to_line_item(next_line_item, selected_zone_index: @selected_zone_index, carrier_product_price: @carrier_product_price)
      return if r.nil?

      if link.sales_price.use_margin_config?
        if base_line_item && next_line_item.parameters.present? && next_line_item.parameters.keys.include?(:base)
          next_line_item.parameters[:base] = base_line_item.sales_price_amount
          next_line_item.sales_price_amount = base_line_item.sales_price_amount*next_line_item.parameters[:percentage].fdiv(100)
        end

        # TODO: Only weight-based packages are supported for now.
        if next_line_item.parameters.present? && next_line_item.parameters.keys.include?(:weight) && !next_line_item.parameters.keys.include?(:per)
          base_line_item = next_line_item
        end
      end

      next_line_item
    end

    AdvancedPrice.new(
      seller: link.seller,
      buyer: link.buyer,
      price_type: AdvancedPrice::Types::AUTOMATIC,
      cost_price_currency: previous_price.cost_price_currency,
      sales_price_currency: previous_price.sales_price_currency,
      advanced_price_line_items: line_items,
    )
  rescue => e
    ExceptionMonitoring.report!(e)
    nil
  end

  def price_document_with_configurable_surcharges
    # We are going to pass in a "fresh" price document - just meaning that
    # it is a new object. This is important because PriceDocumentContortion
    # will mutate it.
    fresh_price_document = @carrier_product_price.price_document

    if fresh_price_document
      PriceDocumentContortion.build_price_document_with_surcharges(
        price_document: fresh_price_document,
        carrier_product: @carrier_product_price.carrier_product,
        shipping_date: shipping_date,
        include_surcharge_types: include_surcharge_types,
      )
    else
      nil
    end
  end

  def include_surcharge_types
    types = []
    types << "ResidentialSurcharge" if residential
    types << "NonStackableSurcharge" if Array(goods_lines).any?(&:non_stackable?)
    types += Array(carrier_surcharge_types) if carrier_surcharge_types.present?
    types
  end
end
