class Companies::CarrierProductCustomers::Carriers::Products::AddProductsToCustomerCompanyCarrier < ApplicationInteractor

  def initialize(company_id: nil, customer_company_id: nil, customer_carrier_id: nil, data: nil)
    @company_id = company_id
    @customer_company_id = customer_company_id
    @customer_carrier_id = customer_carrier_id
    @data = data
  end

  def run
    Rails.logger.debug @data.inspect

    added_carrier_products_count = 0
    carrier_product = nil
    ActiveRecord::Base.transaction do
      @data.each do |data|
        next if !data[:add_product]
        carrier_product = CarrierProduct.create_carrier_product_from_existing_product(
          company_id: @customer_company_id,
          carrier_id: @customer_carrier_id,
          existing_product_id: data[:carrier_product_id],
          is_locked: true
        )
        added_carrier_products_count += 1
      end
    end

    return InteractorResult.new(carrier_product: carrier_product, added_count: added_carrier_products_count)
  rescue => e
    Rails.logger.debug "AddProductsToCustomerCompanyCarrier #{e.inspect}"
    return InteractorResult.new(error: e)
  end
end

