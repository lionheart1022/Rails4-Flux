module ShipmentPersistence
  extend ActiveSupport::Concern

  private

  def current_company
    current_context.company
  end

  def permitted_shipment_attributes
    shipment_params.slice(*ShipmentForm.permitted_shipment_fields)
  end

  def calculate_shipment_prices
    shipment.carrier_product.calculate_price_chain_for_shipment(
      company_id: shipment.company_id,
      customer_id: shipment.customer_id,
      package_dimensions: shipment.package_dimensions,
      goods_lines: package_dimension_params_as_array.map { |package_dimension_attrs| GoodsLine.new(package_dimension_attrs.slice(*ShipmentForm.permitted_goods_line_fields)) },
      sender_country_code: shipment.sender.country_code,
      sender_zip_code: shipment.sender.zip_code,
      recipient_country_code: shipment.recipient.country_code,
      recipient_zip_code: shipment.recipient.zip_code,
      shipping_date: shipment.shipping_date,
      distance_in_kilometers: distance_in_kilometers,
      dangerous_goods: shipment.dangerous_goods?,
      residential: shipment.recipient.residential?,
    )
  end

  def build_shipment_goods
    shipment_goods = ShipmentGoods.new(shipment: shipment, volume_type: carrier_product.loading_meter? ? "loading_meter" : "volume_weight")

    package_dimension_params_as_array.each do |package_dimension_attrs|
      line_attrs = package_dimension_attrs.slice(*ShipmentForm.permitted_goods_line_fields)
      line = GoodsLine.new(line_attrs)
      line.assign_volume_weight_via_carrier_product(carrier_product)

      shipment_goods.lines << line
    end

    shipment_goods
  end

  def build_package_dimensions
    package_dimensions_array = PackageDimensionsFormParams.new(package_dimension_params_as_array).as_array
    PackageDimensionsBuilder.build_from_package_dimensions_array(carrier_product: carrier_product, package_dimensions_array: package_dimensions_array)
  end

  def package_dimension_params_as_array
    if shipment_params["package_dimensions"].is_a?(Array)
      shipment_params["package_dimensions"]
    else
      shipment_params["package_dimensions"].with_indifferent_access.values
    end
  end

  def sender_attributes
    @permitted_sender_attributes ||=
      if shipment_params["sender_attributes"].present?
        shipment_params["sender_attributes"].to_h.slice(*ShipmentForm.permitted_contact_fields)
      else
        {}
      end
  end

  def recipient_attributes
    @permitted_recipient_attributes ||=
      if shipment_params["recipient_attributes"].present?
        shipment_params["recipient_attributes"].to_h.slice(*ShipmentForm.permitted_contact_fields)
      else
        {}
      end
  end

  def auto_book_shipment
    if auto_book_shipment?
      carrier_product.auto_book_shipment(company_id: shipment.company_id, customer_id: shipment.customer_id, shipment_id: shipment.id)
    end
  end

  def enqueue_prebook_job
    if enqueue_prebook_job?
      PrebookAndPersistJob.perform_later(shipment.id)
    end
  end

  def auto_book_shipment?
    customer_carrier_product.enable_autobooking? &&
      customer_carrier_product.automatically_autobook? &&
      carrier_product.supports_shipment_auto_booking?
  end

  def enqueue_prebook_job?
    carrier_product.prebook_step? &&
      FeatureFlag.active.where(resource_type: "Company", resource_id: current_company.id, identifier: "ups-prebook-step").exists?
  end

  def distance_in_kilometers
    return @distance_in_kilometers if defined?(@distance_in_kilometers)

    @distance_in_kilometers =
      if shipment.carrier_product.distance_based_product?
        route_calculation = RouteCalculation.new(from: shipment.sender.as_address, to: shipment.recipient.as_address)
        route_calculation.shortest_distance_in_km
      end
  end
end
