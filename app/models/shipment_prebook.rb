class ShipmentPrebook
  class << self
    def check!(*args)
      new(*args).check!
    end
  end

  attr_reader :params
  attr_reader :current_context

  def initialize(params:, current_context:)
    @params = params
    @current_context = current_context # TODO: Currently this is not used
  end

  def check!
    if shipment.carrier_product.prebook_step?
      result = shipment.carrier_product.perform_prebook_step(shipment)

      if result.is_a?(SurchargeWarningResult)
        result.customer_price = shipment.carrier_product.customer_price_for_shipment(
          company_id: shipment.company_id,
          customer_id: shipment.customer_id,
          package_dimensions: shipment.package_dimensions,
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
      end

      result
    else
      OKResult.new
    end
  rescue => e
    ExceptionMonitoring.report!(e)
    ErrorResult.new("Unexpected prebook-check error")
  end

  private

  def shipment_params
    params.fetch(:shipment, {}).permit(
      :shipment_type,
      :dangerous_goods,
      :description,
      :shipping_date,
      :dutiable,
      :customs_amount,
      :customs_currency,
      :customs_code,
      :sender_attributes => [
        :company_name,
        :attention,
        :phone_number,
        :email,
        :address_line1,
        :address_line2,
        :address_line3,
        :zip_code,
        :city,
        :country_code,
        :state_code,
        :residential,
      ],
      :recipient_attributes => [
        :company_name,
        :attention,
        :phone_number,
        :email,
        :address_line1,
        :address_line2,
        :address_line3,
        :zip_code,
        :city,
        :country_code,
        :state_code,
        :residential,
      ]
    )
  end

  def shipment
    @shipment ||= begin
      s = Shipment.new(shipment_params)

      # FIXME: This is not ideal because it means all the carrier products are accessible.
      s.carrier_product = CarrierProduct.find(params[:shipment][:carrier_product_id])

      s.customer_id = params[:customer_id]
      s.company_id = s.carrier_product.company_id

      package_dimensions_array = PackageDimensionsFormParams.new(params[:shipment][:package_dimensions]).as_array
      s.package_dimensions = PackageDimensionsBuilder.build_from_package_dimensions_array(carrier_product: s.carrier_product, package_dimensions_array: package_dimensions_array)

      s
    end
  end

  class Result
    attr_accessor :estimated_arrival_date
  end

  class OKResult < Result
  end

  class ErrorResult < Result
    attr_reader :message

    def initialize(message)
      @message = message
    end
  end

  class SurchargeWarningResult < Result
    attr_reader :surcharges
    attr_accessor :customer_price

    def initialize(surcharges)
      @surcharges = surcharges
    end
  end

  class Surcharge
    attr_accessor :identifier
    attr_accessor :type
    attr_accessor :description

    def initialize(params = {})
      params.each do |attr, value|
        self.public_send("#{attr}=", value)
      end
    end
  end
end
