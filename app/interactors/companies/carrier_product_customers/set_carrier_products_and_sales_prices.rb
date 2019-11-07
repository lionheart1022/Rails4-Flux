class Companies::CarrierProductCustomers::SetCarrierProductsAndSalesPrices < ApplicationInteractor


  # @param [Integer] customer_id
  # @param [Array] carrier_product_options An array of options for the carrier product. Each entry should be a Hash for keys :id, :enable_autobooking, :automatically_autobook, :margin_percentage
  def initialize(company_id: nil, customer_id: nil, carrier_product_options: nil)
    @company_id              = company_id
    @customer_id             = customer_id
    @carrier_product_options = carrier_product_options
  end


  # Set the allowed carrier products and sales price for a customer
  #
  # Existing enabled carrier products not in the allowed list will be disabled
  def run
    Rails.logger.debug @carrier_product_options
    CustomerCarrierProduct.transaction do

      @carrier_product_options.each do |carrier_product_option|
        carrier_product_id = carrier_product_option[:carrier_product_id]
        margin_percentage  = carrier_product_option[:margin_percentage]
        is_disabled        = carrier_product_option[:is_disabled]

        carrier_product = CarrierProduct.find_company_carrier_product(company_id: @customer_id, carrier_product_id: carrier_product_id)
        sales_price     = SalesPrice.find_sales_price_from_reference(reference_id: carrier_product_id, reference_type: CarrierProduct.to_s)

        carrier_product.is_disabled = is_disabled
        carrier_product.save!

        sales_price.margin_percentage = margin_percentage
        sales_price.save!
      end
    end

    return InteractorResult.new(
      carrier: @carrier
    )
  rescue => e
    Rails.logger.debug "SetCarrierProductsAndSalesPrices #{e}"
    return InteractorResult.new(error: e)
  end
end
