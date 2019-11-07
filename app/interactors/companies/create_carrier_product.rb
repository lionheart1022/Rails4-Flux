class Companies::CreateCarrierProduct
  attr_internal_accessor :current_company
  attr_internal_accessor :carrier
  attr_internal_accessor :form
  attr_reader :result

  def initialize(form:, carrier:, current_company:)
    self.form = form
    self.carrier = carrier
    self.current_company = current_company
  end

  def perform!
    if form.valid?
      carrier_product = CarrierProduct.new(form.record_attributes)
      carrier_product.carrier = carrier
      carrier_product.company_id = carrier.company_id
      carrier_product.state = CarrierProduct::States::UNLOCKED_FOR_CONFIGURING
      carrier_product.credentials = {}
      carrier_product.save!

      @result = Result.new(carrier_product)
    else
      @result = Result.new
    end
  end

  def success?
    result ? result.success? : false
  end

  class Result
    attr_reader :carrier_product

    def initialize(carrier_product = nil)
      @carrier_product = carrier_product
    end

    def success?
      carrier_product.present?
    end
  end

  private_constant :Result
end
