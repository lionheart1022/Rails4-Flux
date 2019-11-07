class PackageUpdate < ActiveRecord::Base
  belongs_to :feedback_file, class_name: "CarrierFeedbackFile"
  belongs_to :package
  belongs_to :package_recording

  class PackageNotFoundInFeedbackFile < StandardError
    attr_reader :package, :shipment

    def initialize(msg, package:, shipment:)
      super(msg)
      @package = package
      @shipment = shipment
    end
  end

  def can_apply?
    return false if failed_to_apply?
    return applied_at.nil? if package_recording

    false
  end

  def applied?
    applied_at?
  end

  def apply_change!
    return if applied?

    begin
      transaction { apply_change_without_transaction! }

      EventManager.handle_event(event: Shipment::Events::UPDATE_SHIPMENT_PRICE, event_arguments: { shipment_id: package.shipment_id })
    rescue PackageNotFoundInFeedbackFile => e
      update!(
        failed_at: Time.zone.now,
        failure_reason: "package_count_mismatch",
        failure_handled: false,
      )
    end
  end

  def failed_to_apply?
    failed_at? && !failure_handled?
  end

  def failure_text
    case failure_reason
    when "package_count_mismatch"
      "Package count mismatch"
    end
  end

  private

  def apply_change_without_transaction!
    shipment = package.shipment
    shipment_packages = Package.where(shipment: shipment)
    feedback_package_updates = PackageUpdate.where(feedback_file: feedback_file)
    carrier_product = shipment.carrier_product

    updated_package_dimensions_array = shipment.package_dimensions.dimensions.each_with_index.map do |package_dimension, package_index|
      package = shipment_packages.find_by!(package_index: package_index)
      package_update = feedback_package_updates.find_by(package: package)

      if package_update.nil?
        raise PackageNotFoundInFeedbackFile.new("Could not find expected package", package: package, shipment: shipment)
      end

      package_update_recording = package_update.package_recording

      dim_without_volume_weight = PackageDimension.new(
        length: package_dimension.length,
        width: package_dimension.width,
        height: package_dimension.height,
        weight: package_update_recording.weight_value,
        volume_weight: nil,
      )

      volume_weight = carrier_product.volume_weight(dimension: dim_without_volume_weight)

      PackageDimension.new(
        length: dim_without_volume_weight.length,
        width: dim_without_volume_weight.width,
        height: dim_without_volume_weight.height,
        weight: dim_without_volume_weight.weight,
        volume_weight: volume_weight,
      )
    end

    updated_package_dimensions = PackageDimensions.new(dimensions: updated_package_dimensions_array)

    updated_prices = carrier_product.calculate_price_chain_for_shipment(
      company_id: shipment.company_id,
      customer_id: shipment.customer_id,
      package_dimensions: updated_package_dimensions,
      goods_lines: shipment.goods_lines,
      sender_country_code: shipment.sender.country_code,
      sender_zip_code: shipment.sender.zip_code,
      recipient_country_code: shipment.recipient.country_code,
      recipient_zip_code: shipment.recipient.zip_code,
      shipping_date: shipment.shipping_date,
      distance_in_kilometers: nil, # NOTE: Not sure if we will ever need this feature to work with distance-based carrier products?
      dangerous_goods: shipment.dangerous_goods?,
      residential: shipment.recipient.residential?,
      carrier_surcharge_types: shipment.additional_surcharges.map(&:surcharge_type),
    )

    apply_per_package_surcharges!(updated_prices)

    shipment.advanced_prices.each do |advanced_price|
      # Only keep the manual prices as the automatic prices will be replaced
      advanced_price.advanced_price_line_items = advanced_price.advanced_price_line_items.select { |line_item| line_item.price_type == AdvancedPriceLineItem::Types::MANUAL }
    end

    updated_prices.each do |new_advanced_price|
      existing_advanced_price = shipment.advanced_prices.select { |advanced_price| advanced_price.seller == new_advanced_price.seller }.first

      if existing_advanced_price
        existing_advanced_price.advanced_price_line_items << new_advanced_price.advanced_price_line_items
      else
        shipment.advanced_prices << new_advanced_price
      end
    end

    shipment_package_updates = feedback_package_updates.where(package_id: shipment_packages.pluck(:id))

    shipment_package_updates.each do |package_update|
      shipment.info(description: "Package #{package_update.package.unique_identifier}, feedback from carrier. Weight: #{package_update.package.active_recording.weight_value} #{package_update.package.active_recording.weight_unit} → #{package_update.package_recording.weight_value} #{package_update.package_recording.weight_unit}")

      package_update.package.update!(active_recording: package_update.package_recording)
    end

    shipment_package_updates.update_all(applied_at: Time.zone.now)
  end

  def apply_per_package_surcharges!(advanced_prices)
    shipment = package.shipment
    root_carrier_product = shipment.carrier_product.first_unlocked_product_in_owner_chain

    advanced_prices.each do |advanced_price|
      shipment.package_dimensions.dimensions.each_with_index do |dimension, index|
        package = Package.find_by!(shipment: shipment, package_index: index)
        matching_surcharge_types = Array(package.applicable_surcharge_types)

        root_carrier_product.surcharges_to_apply.each do |surcharge|
          if surcharge.carrier_feedback_surcharge? && matching_surcharge_types.include?(surcharge.type)
            case
            when surcharge.price_percentage?
              # TODO: This is not supported to begin with.
            when surcharge.price_fixed?
              advanced_price.advanced_price_line_items <<
                AdvancedPriceLineItem.new(
                  description: surcharge.description,
                  cost_price_amount: surcharge.charge_value_as_numeric,
                  sales_price_amount: surcharge.charge_value_as_numeric,
                  times: 1,
                  parameters: nil,
                  price_type: AdvancedPriceLineItem::Types::AUTOMATIC,
                )
            end
          end
        end
      end
    end
  end
end
