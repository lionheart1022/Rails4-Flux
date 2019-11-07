class Companies::CarrierSurchargesView
  attr_reader :current_company
  attr_reader :carrier

  def initialize(current_company:, carrier:)
    @current_company = current_company
    @carrier = carrier
  end

  def can_edit_surcharges?
    if cp = carrier_products.first
      cp.state == CarrierProduct::States::UNLOCKED_FOR_CONFIGURING
    else
      true
    end
  end

  def enabled_surcharges
    @enabled_surcharges ||= carrier.enabled_surcharges
  end

  def carrier_products
    @carrier_products ||= begin
      CarrierProduct
        .find_enabled_company_carrier_products(company_id: current_company.id, carrier_id: carrier.id)
        .sort_by { |p| p.name.downcase }
    end
  end

  def carrier_product_surcharge_rows
    all_surcharges_on_products = SurchargeOnProduct.where(carrier_product_id: carrier.carrier_products.pluck(:id))
    all_surcharges_on_products.load

    carrier_products.map do |carrier_product|
      row = CarrierProductSurchargeRow.new(carrier_product)

      row.surcharge_columns = enabled_surcharges.map do |surcharge_on_carrier|
        surcharge_on_product = all_surcharges_on_products.detect do |s|
          s.parent == surcharge_on_carrier && s.carrier_product == carrier_product
        end

        CarrierProductSurchargeColumn.new(surcharge_on_carrier, surcharge_on_product)
      end

      row
    end
  end

  CarrierProductSurchargeRow = Struct.new(:carrier_product, :surcharge_columns)
  CarrierProductSurchargeColumn = Struct.new(:surcharge_on_carrier, :surcharge_on_product)
end
