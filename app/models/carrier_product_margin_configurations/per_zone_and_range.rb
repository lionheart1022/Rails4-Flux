module CarrierProductMarginConfigurations
  class PerZoneAndRange < CarrierProductMarginConfiguration
    class Table
      attr_accessor :price_document
      attr_accessor :selected_zone_index
      attr_accessor :customer
      attr_accessor :carrier_product
      attr_accessor :carrier_product_price

      attr_reader :rows

      def selected_zone_index
        Integer(@selected_zone_index.presence || 0)
      end

      def selected_zone
        price_document.zones[selected_zone_index]
      end

      def build_rows
        @rows = []

        selected_zone = price_document.zones[selected_zone_index]
        selected_zone_price = price_document.zone_prices.detect { |zone_price| zone_price.zone == selected_zone }

        return if selected_zone_price.nil?

        customer_carrier_product = CustomerCarrierProduct.find_by(customer: customer, carrier_product: carrier_product)
        sales_price = customer_carrier_product.try(:sales_price)
        existing_rows =
          if sales_price && sales_price.margin_config && sales_price.margin_config.price_document_hash_matches?(carrier_product_price: carrier_product_price)
            sales_price.margin_config.config_document.try(:[], "zones").try(:[], String(selected_zone_index))
          end

        @rows = selected_zone_price.charges.select { |charge| charge.identifier == "shipment_charge" }.each_with_index.map do |charge, index|
          Row.new(
            price_document: price_document,
            charge: charge,
            existing_data: existing_rows ? existing_rows[index] : nil,
          )
        end
      end

      def assign_row_params(row_params = nil)
        build_rows

        rows_attrs = row_params.values

        @rows.each_with_index do |row, index|
          row_attrs = rows_attrs[index]

          if row.charge_type == row_attrs["charge_type"] && row.json_weight == row_attrs["json_weight"]
            row.margin_amount = row_attrs["margin_amount"]
            row.interval_margin_amount = row_attrs["interval_margin_amount"]
          else
            raise "Mis-match between row and submitted data"
          end
        end
      end

      def save_rows(current_user: nil)
        ActiveRecord::Base.transaction do
          customer_carrier_product = CustomerCarrierProduct.find_or_initialize_by(customer: customer, carrier_product: carrier_product)
          customer_carrier_product.is_disabled = false
          customer_carrier_product.build_sales_price unless customer_carrier_product.sales_price

          sales_price = customer_carrier_product.sales_price
          sales_price.use_margin_config = true

          margin_config =
            if sales_price.margin_config && sales_price.margin_config.price_document_hash_matches?(carrier_product_price: carrier_product_price)
              sales_price.margin_config.dup
            else
              ::CarrierProductMarginConfigurations::PerZoneAndRange.new
            end
          margin_config.created_by = current_user
          margin_config.generate_price_document_hash(carrier_product_price: carrier_product_price)

          margin_config.config_document ||= {}
          margin_config.config_document["zones"] ||= {}
          margin_config.config_document["zones"][String(selected_zone_index)] = rows.map(&:as_json)
          margin_config.save!

          sales_price.margin_config = margin_config
          customer_carrier_product.save!

          margin_config.update!(owner: sales_price)
        end

        true
      end
    end

    class Row
      include ActiveModel::Model

      attr_accessor :price_document
      attr_accessor :margin_amount
      attr_accessor :interval_margin_amount
      attr_accessor :charge_type
      attr_reader :charge
      attr_accessor :weight

      delegate :currency, to: :price_document

      def charge=(charge)
        @charge = charge

        self.charge_type = charge_class_name(charge)

        case charge_type
        when "FlatWeightCharge"
          self.weight = { "value" => charge.weight.to_s }
        when "WeightRangeCharge"
          self.weight = { "low" => charge.weight_low.to_s, "high" => charge.weight_high.to_s, "interval" => charge.interval.to_s }
        else
          Rails.logger.error "TODO: #{charge_type} was not recognized"
          self.weight = {}
        end
      end

      def existing_data=(data)
        return if data.blank?

        self.margin_amount = data["margin_amount"]
        self.interval_margin_amount = data["interval_margin_amount"]
      end

      def json_weight
        JSON.generate(weight)
      end

      def json_weight=(value)
        self.weight = JSON.parse(value)
      end

      def weight_value
        weight["value"]
      end

      def weight_low_value
        weight["low"]
      end

      def weight_high_value
        weight["high"]
      end

      def formatted_weight_value
        case charge_type
        when "FlatWeightCharge"
          ActiveSupport::NumberHelper.number_to_rounded(weight_value, precision: 2, strip_insignificant_zeros: true)
        when "WeightRangeCharge"
          low = ActiveSupport::NumberHelper.number_to_rounded(weight_low_value, precision: 2, strip_insignificant_zeros: true)
          high = ActiveSupport::NumberHelper.number_to_rounded(weight_high_value, precision: 2, strip_insignificant_zeros: true)

          "#{low}-#{high}"
        else
          Rails.logger.error "TODO: #{charge_type} was not recognized"
          nil
        end
      end

      def formatted_cost_price
        case charge_type
        when "FlatWeightCharge"
          value = ActiveSupport::NumberHelper.number_to_rounded(charge.amount, precision: 2, strip_insignificant_zeros: true)
          "#{value} #{currency}"
        when "WeightRangeCharge"
          low = ActiveSupport::NumberHelper.number_to_rounded(charge.price_low, precision: 2, strip_insignificant_zeros: true)
          interval_price = ActiveSupport::NumberHelper.number_to_rounded(charge.price_per_interval, precision: 2, strip_insignificant_zeros: true)
          interval = ActiveSupport::NumberHelper.number_to_rounded(charge.interval, precision: 2, strip_insignificant_zeros: true)

          "#{low} #{currency} + #{interval_price} #{currency}/#{interval} #{weight_unit}"
        else
          Rails.logger.error "TODO: #{charge_type} was not recognized"
          nil
        end
      end

      def base_cost_price
        case charge_type
        when "FlatWeightCharge"
          charge.amount
        when "WeightRangeCharge"
          charge.price_low
        else
          Rails.logger.error "TODO: #{charge_type} was not recognized"
          nil
        end
      end

      def weight_unit
        "kg"
      end

      def as_json
        {
          "weight" => weight,
          "charge_type" => charge_type,
          "margin_amount" => normalized_margin_amount,
          "interval_margin_amount" => normalized_interval_margin_amount,
        }
      end

      private

      def charge_class_name(charge)
        charge.class.name.split("::").last
      end

      def normalized_margin_amount
        margin_amount.sub(",", ".") if margin_amount
      end

      def normalized_interval_margin_amount
        interval_margin_amount.sub(",", ".") if interval_margin_amount
      end
    end
  end
end
