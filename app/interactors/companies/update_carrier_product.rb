class Companies::UpdateCarrierProduct
  attr_internal_accessor :current_company
  attr_internal_accessor :carrier_product
  attr_internal_accessor :form
  attr_reader :result

  def initialize(form:, carrier_product:, current_company:)
    self.form = form
    self.carrier_product = carrier_product
    self.current_company = current_company
  end

  def perform!
    if form.valid?
      carrier_product.assign_attributes(form.record_attributes)
      carrier_product.save!

      @result = Result.new(true)
    else
      @result = Result.new
    end
  end

  def success?
    result ? result.success? : false
  end

  class Result
    attr_reader :success
    alias_method :success?, :success

    def initialize(success = false)
      @success = success
    end
  end

  private_constant :Result
end
