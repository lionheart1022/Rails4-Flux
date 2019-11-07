class Shared::Shipments::GetPrices < ApplicationInteractor

  def initialize(company_id: nil, customer_id: nil, sender_params: nil, recipient_params: nil, shipping_date: nil, shipment_type: nil, dangerous_goods: false, residential: false, package_dimensions: [], goods_lines: [], is_company: false, custom_products_only: nil, chain: nil)
    @company_id         = company_id
    @customer_id        = customer_id
    @sender_params      = sender_params
    @recipient_params   = recipient_params
    @shipping_date      = shipping_date
    @shipment_type      = shipment_type
    @dangerous_goods    = dangerous_goods
    @residential        = residential
    @package_dimensions = package_dimensions
    @goods_lines        = parse_goods_lines(goods_lines)
    @is_company         = is_company
    @custom_products_only    = custom_products_only
    @chain              = chain

    self
  end

  def run
    tms_parse_package_dimensions = Benchmark.measure do
      parse_package_dimensions
    end

    tms_find_eligable_products = Benchmark.measure do
      find_eligable_products
    end

    tms_filter_products = Benchmark.measure do
      filter_products
    end

    tms_get_route_if_distance = Benchmark.measure do
      get_route_if_distance
    end

    tms_map_prices = Benchmark.measure do
      map_prices
    end

    log_message = sprintf(
      "Shared::Shipments::GetPrices - benchmark - tms_parse_package_dimensions=%.2fs tms_find_eligable_products=%.2fs tms_filter_products=%.2fs tms_get_route_if_distance=%.2fs tms_map_prices=%.2fs",
      tms_parse_package_dimensions.real,
      tms_find_eligable_products.real,
      tms_filter_products.real,
      tms_get_route_if_distance.real,
      tms_map_prices.real,
    )

    Rails.logger.info log_message

    return InteractorResult.new(
      carrier_products_and_prices: @carrier_products_and_prices,
      distance_based_product_is_present: @distance_based_product_is_present)
  rescue => e
    Rails.logger.error "GetPrices#run #{e.inspect}"
    return InteractorResult.new(error: e)
  end

  private

    def parse_package_dimensions
      @package_dimensions = PackageDimensionsFormParams.new(@package_dimensions).as_package_dimensions_object
    end

    def parse_goods_lines(goods_lines)
      return [] if goods_lines.blank?

      lines_as_array =
        if goods_lines.is_a?(Array)
          goods_lines
        else
          goods_lines.values
        end

      lines_as_array.map do |line_attrs|
        permitted_line_attrs = line_attrs.with_indifferent_access.slice(*ShipmentForm.permitted_goods_line_fields)
        GoodsLine.new(permitted_line_attrs)
      end
    end

    def find_eligable_products
      @carrier_products = CustomerCarrierProduct
        .includes(:carrier_product_price)
        .find_enabled_customer_carrier_products(customer_id: @customer_id)
        .sort_by{ |c| c.name.downcase }

      @carrier_products = @carrier_products.select{ |cp| !cp.chain? } if !@chain
      @carrier_products = @carrier_products.select{ |cp| cp.custom? } if @custom_products_only
    end

    def filter_products
      is_import = @shipment_type == 'Import'

      @filtered_carrier_products = @carrier_products
      .select do |cp|
        @custom_products_only ? cp.custom? : true
      end
      .select do |cp|
        cp.eligible?(
          sender_country_code:      @sender_params[:country_code],
          destination_country_code: @recipient_params[:country_code],
          import:                   is_import,
          number_of_packages:       @package_dimensions.number_of_packages
        )
      end
      .select do |cp|
        cp.matches_rules?(
          shipment_weight: @package_dimensions.total_weight,
          number_of_packages: @package_dimensions.number_of_packages,
          recipient_country_code: @recipient_params[:country_code],
        )
      end
    end

    def get_route_if_distance
      @distance_based_product_is_present = @filtered_carrier_products.any? { |cp| CarrierProduct.distance_based_product?(@carrier_products, cp) }

      if @distance_based_product_is_present
        from_address = Address.new(@sender_params.slice(:country_code, :state_code, :city, :zip_code, :address_line1, :address_line2))
        to_address = Address.new(@recipient_params.slice(:country_code, :state_code, :city, :zip_code, :address_line1, :address_line2))

        if from_address.to_flat_string.blank? || to_address.to_flat_string.blank?
          @distance_in_kilometers = nil
          return
        end

        route_calculation = RouteCalculation.new(from: from_address, to: to_address)
        @distance_in_kilometers = route_calculation.shortest_distance_in_km
      end
    end

    def map_prices
      @carrier_products_and_prices = @filtered_carrier_products.map do |cp|
        sales_price = SalesPrice.find_sales_price_from_customer_and_carrier_product(
          customer_id:        @customer_id,
          carrier_product_id: cp.id
        )

        # attempts to calculate price for shipment based on given parameters
        price = cp.customer_price_for_shipment(
          company_id: @company_id,
          customer_id: @customer_id,
          sender_country_code: @sender_params[:country_code],
          sender_zip_code: @sender_params[:zip_code],
          recipient_country_code: @recipient_params[:country_code],
          recipient_zip_code: @recipient_params[:zip_code],
          shipping_date: @shipping_date,
          package_dimensions: @package_dimensions,
          goods_lines: @goods_lines,
          distance_in_kilometers: @distance_in_kilometers,
          dangerous_goods: @dangerous_goods,
          residential: @residential,
        )

        Rails.logger.debug "price #{price.inspect}"

        # package carrier product id, name, price
        {
          carrier_product_id:           cp.id,
          carrier_product_name:         cp.name,
          carrier_product_transit_time: cp.transit_time,
          carrier_product_prebook_step: FeatureFlag.active.where(resource_type: "Company", resource_id: @company_id, identifier: "ups-prebook-step").exists? && cp.prebook_step?,
          # carrier_product_is_selected:  cp.id == params[:selected_carrier_product_id].to_i,
          price:                        price
        }
      end
    end

end

