class EconomicCarrierProductMapping
  attr_accessor :company
  attr_accessor :carrier

  def initialize(company:, carrier:)
    self.company = company
    self.carrier = carrier
  end

  def carrier_products
    load!
    @carrier_products
  end

  private

  def load!
    @carrier_products =
      carrier_product_records.map do |carrier_product_record|
        product_mapping_record = EconomicProductMapping.find_or_initialize_by(owner: company, item: carrier_product_record)
        CarrierProductWithMapping.new(carrier_product_record, product_mapping_record)
      end
  end

  def carrier_product_records
    CarrierProduct
      .find_enabled_company_carrier_products(company_id: company.id, carrier_id: carrier.id)
      .sort_by { |p| p.name.downcase }
  end

  class CarrierProductWithMapping < SimpleDelegator
    attr_accessor :product_mapping

    def initialize(carrier_product, product_mapping)
      self.product_mapping = product_mapping
      super(carrier_product)
    end
  end

  private_constant :CarrierProductWithMapping
end
