class Companies::Carriers::BatchDisableCarriers < ApplicationInteractor

  def initialize(company_id: nil, carrier_product_customer_id: nil, carrier_params: nil)
    @company_id                  = company_id
    @carrier_params              = carrier_params
    @carrier_product_customer_id = carrier_product_customer_id
    return self
  end

  def run
    ids = []
    Carrier.transaction do
      @carrier_params.each do |disabled, id|
        carrier = Carrier.find_company_carrier(company_id: @carrier_product_customer_id, carrier_id: id)
        carrier.update_attributes!(disabled: disabled)
        ids << carrier.id
      end
    end

    return InteractorResult.new(ids: ids)
  rescue => e
    Rails.logger.debug e.inspect
    return InteractorResult.new(error: e)
  end

end
