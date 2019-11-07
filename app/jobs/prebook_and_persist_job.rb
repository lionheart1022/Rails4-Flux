class PrebookAndPersistJob < ActiveJob::Base
  queue_as :booking

  def perform(shipment_id)
    shipment = Shipment.find(shipment_id)

    if shipment.carrier_product.prebook_step?
      result = shipment.carrier_product.perform_prebook_step(shipment)

      shipment.update!(estimated_arrival_date: result.estimated_arrival_date)

      if result.is_a?(ShipmentPrebook::SurchargeWarningResult)
        updated_prices = shipment.carrier_product.calculate_price_chain_for_shipment(
          company_id: shipment.company_id,
          customer_id: shipment.customer_id,
          package_dimensions: shipment.package_dimensions,
          goods_lines: shipment.goods_lines,
          sender_country_code: shipment.sender.country_code,
          sender_zip_code: shipment.sender.zip_code,
          recipient_country_code: shipment.recipient.country_code,
          recipient_zip_code: shipment.recipient.zip_code,
          shipping_date: shipment.shipping_date,
          distance_in_kilometers: nil, # NOTE: Not sure if we will ever need this feature to work with distance-based carrier products?
          dangerous_goods: shipment.dangerous_goods?,
          residential: shipment.recipient.residential?,
          carrier_surcharge_types: result.surcharges.map(&:type),
        )

        if updated_prices.present?
          shipment.advanced_prices = updated_prices
          shipment.additional_surcharges = result.surcharges.map do |surcharge|
            ShipmentAdditionalSurcharge.new(surcharge_type: surcharge.type)
          end
          shipment.save!
        end
      end
    end
  end
end
