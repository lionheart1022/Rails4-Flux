class Companies::CarrierProductCustomers::Carriers::AddCarriersToCustomerCompany < ApplicationInteractor

  def initialize(company_id: nil, customer_company_id: nil, data: nil)
    @company_id = company_id
    @customer_company_id = customer_company_id
    @data = data
  end

  def run
    added_carriers_count = 0
    ActiveRecord::Base.transaction do
      @data.each do |data|
        next if !data[:add_carrier]

        owner_carrier = Carrier.find_company_carrier(company_id: @company_id, carrier_id: data[:carrier_id])
        new_carrier = Carrier.create_carrier_from_existing_carrier(company_id: @customer_company_id, existing_carrier_id: owner_carrier.id)
        added_carriers_count += 1
        next if !data[:add_products]

        owner_carrier.carrier_products.each do |owner_product|
          CarrierProduct.create_carrier_product_from_existing_product(company_id: @customer_company_id, carrier_id: new_carrier.id, existing_product_id: owner_product.id, is_locked: true)
        end
      end
    end

    return InteractorResult.new(carrier: @carrier, added_count: added_carriers_count)
  rescue => e
    Rails.logger.debug "AddCarriersToCustomerCompany #{e.inspect}"
    return InteractorResult.new(error: e)
  end
end

