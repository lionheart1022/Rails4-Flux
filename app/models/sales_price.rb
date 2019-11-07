class SalesPrice < ActiveRecord::Base

	belongs_to :reference, polymorphic: true
  belongs_to :margin_config, class_name: "CarrierProductMarginConfiguration"
  validates :margin_percentage, :numericality => { :greater_than_or_equal_to => 0 }, allow_nil: true

	class << self

    def build_sales_price(reference_id: nil, reference_type: nil, margin_percentage: nil)
      sales_price = self.new({
        reference_id:      reference_id,
        reference_type:    reference_type,
        margin_percentage: margin_percentage,
      })

      return sales_price
    end

		def create_sales_price(reference_id: nil, reference_type: nil, margin_percentage: nil)
			sales_price = build_sales_price(reference_id: reference_id, reference_type: reference_type, margin_percentage: margin_percentage)
			sales_price.save!

			return sales_price
    end

    def find_sales_price_from_customer_and_carrier_product(customer_id: nil, carrier_product_id: nil)
      self
      .joins('INNER JOIN customer_carrier_products ON sales_prices.reference_id = customer_carrier_products.id')
      .where(reference_type: CustomerCarrierProduct.to_s)
      .where(customer_carrier_products: { customer_id: customer_id, carrier_product_id: carrier_product_id }).first
    end

    def find_sales_price_from_reference(reference_id: nil, reference_type: nil)
      self.where(reference_id: reference_id, reference_type: reference_type).first
    end

	end

  # Returns true if sales price references a carrier product
  #
  def carrier_product?
    self.reference_type == CarrierProduct.to_s
  end

  # Returns true if sales price references a customer carrier product
  #
  def customer_carrier_product?
    self.reference_type == CustomerCarrierProduct.to_s
  end

  # returns true if sales price can be used for price calculations
  #
  def active?
    if use_margin_percentage?
      if carrier_product?
        margin_specified? && reference.is_locked_for_configuring?
      else
        margin_specified?
      end
    else
      if carrier_product?
        margin_config.present? && reference.is_locked_for_configuring?
      else
        margin_config.present?
      end
    end
  end

  # returns true if sales price doesnt meet the requirements for price calculation
  #
  def inactive?
    !self.active?
  end

  def margin_specified?
    self.margin_percentage.present?
  end

  def use_margin_percentage?
    !use_margin_config?
  end

  def conditionally_apply_margin_to_line_item(line_item, selected_zone_index:, carrier_product_price:)
    if use_margin_percentage?
      if line_item.should_apply_margin?
        line_item.sales_price_amount *= self.margin_percentage.fdiv(100) + 1
      end

      if line_item.parameters.present? && line_item.parameters.keys.include?(:base)
        line_item.parameters[:base] *= self.margin_percentage.fdiv(100) + 1
      end
    else
      return unless margin_config.price_document_hash_matches?(carrier_product_price: carrier_product_price)

      config_document = margin_config.config_document
      selected_zone = config_document["zones"][String(selected_zone_index)]

      return if selected_zone.nil?

      margin_amount = nil

      # TODO: Only weight-based packages are supported for now.
      if line_item.parameters.present? && line_item.parameters.keys.include?(:weight) && !line_item.parameters.keys.include?(:per)
        selected_zone.each do |row|
          case row["charge_type"]
          when "FlatWeightCharge"
            if BigDecimal(row["weight"]["value"]) == line_item.parameters[:weight]
              if row["margin_amount"].present?
                margin_amount = BigDecimal(row["margin_amount"])
                break
              else
                return
              end
            end
          when "WeightRangeCharge"
            if line_item.parameters[:weight] >= BigDecimal(row["weight"]["low"]) && line_item.parameters[:weight] <= BigDecimal(row["weight"]["high"])
              if row["margin_amount"].present?
                base_margin_amount = BigDecimal(row["margin_amount"])
                interval_margin_amount = BigDecimal(row["interval_margin_amount"].presence || "0")

                interval = BigDecimal(row["weight"]["interval"].presence || "1")
                diff = line_item.parameters[:weight] - BigDecimal(row["weight"]["low"])
                margin_amount = base_margin_amount + (diff/interval).ceil * interval_margin_amount

                break
              else
                return
              end
            end
          else
            Rails.logger.error "TODO: #{row['charge_type']} was not recognized"
          end
        end

        line_item.sales_price_amount += margin_amount if margin_amount
      end
    end

    line_item
  end
end
