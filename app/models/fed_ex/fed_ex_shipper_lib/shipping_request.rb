class FedExShipperLib
  class ShippingRequest
    CustomsDetails = Struct.new(:currency, :amount, :code)
    PackageLineItem = Struct.new(:weight, :width, :height, :length)

    attr_reader :credentials,
      :shipment,
      :sender,
      :recipient,
      :carrier_product

    delegate :developer_password, :developer_key, :account_number,
      :meter_number, to: :credentials

    delegate :service, to: :carrier_product

    delegate :currency, :amount, :code, to: :customs, prefix: true

    delegate :attention, :company_name, :phone_number, :email, :address_line1,
      :address_line2, :zip_code, :country_code, :country_name, :city,
      :state_code, to: :sender, prefix: true

    delegate :attention, :company_name, :phone_number, :email, :address_line1,
      :address_line2, :zip_code, :country_code, :country_name, :city,
      :state_code, to: :recipient, prefix: true

    delegate :description, :reference, to: :shipment

    def initialize(
      credentials:,
      shipment:,
      sender:,
      recipient:,
      carrier_product:
    )
      @credentials     = credentials
      @shipment        = shipment
      @sender          = sender
      @recipient       = recipient
      @carrier_product = carrier_product
    end

    def as_string
      erb_shipment_template.result(binding)
    end

    def customs
      if !shipment.dutiable? && international_document?
        CustomsDetails.new("EUR", "0.00", nil)
      elsif !shipment.dutiable? && is_within_eu?
        CustomsDetails.new("EUR", "0.00", nil)
      else
        CustomsDetails.new(
          shipment.customs_currency,
          shipment_customs_amount,
          shipment.customs_code
        )
      end
    end

    def dutiable?
      shipment.dutiable? || is_within_eu? || international_document?
    end

    private

    def is_within_eu?
      sender.in_eu? && recipient.in_eu?
    end

    def shipment_customs_amount
      ActiveSupport::NumberHelper.number_to_rounded(
        shipment.customs_amount,
        precision: 2
      )
    end

    def package_dimension_list
      shipment.package_dimensions.dimensions.map do |dimension|
        weight =
          case weight_unit
          when "KG"
            dimension.weight
          when "LB"
            convert_kg_to_lb(dimension.weight)
          end

        width, height, length =
          case dimension_unit
          when "CM"
            [
              dimension.width,
              dimension.height,
              dimension.length,
            ]
          when "IN"
            [
              convert_cm_to_in(dimension.width).ceil,
              convert_cm_to_in(dimension.height).ceil,
              convert_cm_to_in(dimension.length).ceil,
            ]
          end

        PackageLineItem.new(weight, width, height, length)
      end
    end

    def dimension_unit
      carrier_product.fed_ex_dimension_unit
    end

    def weight_unit
      carrier_product.fed_ex_weight_unit
    end

    def total_weight_in_proper_unit
      case weight_unit
      when "KG"
        shipment.package_dimensions.total_weight
      when "LB"
        convert_kg_to_lb(shipment.package_dimensions.total_weight)
      end
    end

    def international_document?
      carrier_product && carrier_product.fed_ex_international_document?
    end

    def shipping_date
      shipment.shipping_date.to_datetime.strftime("%Y-%m-%dT%H:%M:%S%:z")
    end

    def transliterate(string)
      transliterated_string = I18n.transliterate(string)
      escaped_string        = xml_escape(transliterated_string)

      escaped_string
    end

    def xml_escape(string)
      REXML::Text.new(string, false, nil, false).to_s
    end

    def erb_shipment_template
      ERB.new(erb_shipment_template_content)
    end

    def erb_shipment_template_content
      filename = BookingLib.new.path_to_template(
        filename: 'fed_ex_shipment_request_template.xml.erb'
      )
      File.read(filename)
    end

    private

    RATIO_1_LB_1_KG = 1.0/0.453_592_37 # 1 (avoirdupois) pound is 0.453 592 37 kg
    def convert_kg_to_lb(kg_value, round_ndigits: 2)
      (RATIO_1_LB_1_KG * kg_value).round(round_ndigits)
    end

    RATIO_1_IN_1_CM = 1.0/2.54 # 1 inch is 25.4 mm = 2.54 cm
    def convert_cm_to_in(cm_value)
      (RATIO_1_IN_1_CM * cm_value)
    end
  end
end
