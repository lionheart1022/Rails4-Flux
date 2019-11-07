sender          = shipment.sender
recipient       = shipment.recipient
carrier_product = shipment.carrier_product
carrier         = carrier_product.carrier

builder.Shipment do
  builder.CustomerID shipment.customer.id
  builder.CustomerExternalAccountingNumber customer_external_accounting_number if customer_external_accounting_number
  builder.ShipmentId shipment.unique_shipment_id
  builder.State shipment.state
  builder.ShippingDate shipment.shipping_date
  builder.TotalWeight shipment.package_dimensions.total_weight
  builder.TotalVolumeWeight shipment.package_dimensions.total_volume_weight
  builder.CustomsAmount shipment.customs_amount
  builder.CustomsCurrency shipment.customs_currency
  builder.Description shipment.description
  builder.AWB shipment.awb
  builder.NumberOfPackages shipment.number_of_packages
  builder.CustomerReference shipment.reference
  builder.Remarks shipment.remarks
  builder.DeliveryInstructions shipment.delivery_instructions
  builder.Carrier carrier.name
  builder.CarrierProduct carrier_product.name
  builder.CarrierProductCode carrier_product.product_code
  builder.VATIncluded ShipmentVatPolicy.new(shipment).include_vat?

  builder.CarrierProductDetails do
    builder.VolumeWeightType carrier_product.volume_weight_type
    builder.Basis carrier_product.basis
  end

  builder.ParcelshopId shipment.parcelshop_id if shipment.parcelshop_id.present?

  if advanced_price.present?
    builder.Pricing do
      builder.CostPriceAmount advanced_price.total_cost_price_amount.round(2)
      builder.SalesPriceAmount advanced_price.total_sales_price_amount.round(2)
      builder.CostPriceCurrency advanced_price.cost_price_currency
      builder.SalesPriceCurrency advanced_price.sales_price_currency
    end
  end

  if advanced_price.present?
    builder.PriceLines do
      advanced_price.advanced_price_line_items.map do |item|
        builder.PriceLine do
          builder.LineDescription item.description
          builder.LineCostPrice item.cost_price_amount
          builder.LineSalesPrice item.sales_price_amount
          builder.LineQuantity item.times
        end
      end
    end
  end

  builder.Sender do
    builder.CompanyName sender.company_name
    builder.AddressLine1 sender.address_line1
    builder.AddressLine2 sender.address_line2
    builder.AddressLine3 sender.address_line3
    builder.StateCode sender.state_code if sender.state_code.present?
    builder.City sender.city
    builder.ZipCode sender.zip_code
    builder.CountryName sender.country_name
    builder.CountryCode sender.country_code
    builder.Phone sender.phone_number
    builder.Email sender.email
    builder.Attention sender.attention
  end

  builder.Recipient do
    builder.CompanyName recipient.company_name
    builder.AddressLine1 recipient.address_line1
    builder.AddressLine2 recipient.address_line2
    builder.AddressLine3 recipient.address_line3
    builder.StateCode recipient.state_code if recipient.state_code.present?
    builder.City recipient.city
    builder.ZipCode recipient.zip_code
    builder.CountryName recipient.country_name
    builder.CountryCode recipient.country_code
    builder.Phone recipient.phone_number
    builder.Email recipient.email
    builder.Attention recipient.attention
  end

  builder.PackageList do
    shipment.as_goods.tap do |goods|
      goods.ordered_lines.each do |line|
        builder.Package do
          builder.Length line.length
          builder.Width line.width
          builder.Height line.height
          builder.Weight line.weight
          builder.VolumeWeight line.volume_weight
          builder.Quantity line.quantity
          builder.GoodsIdentifier line.goods_identifier
        end
      end
    end
  end
end
