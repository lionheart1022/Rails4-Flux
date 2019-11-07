class Companies::ShipmentExports::Export < ApplicationInteractor

  def initialize(company_id: nil)
    @company_id = company_id

    self
  end

  def run
    find_not_exported
    find_updated
    set_exported

    return InteractorResult.new(new: @not_exported, updated: @updated)
  end

  private

    def find_not_exported
      @not_exported = Shipment
        .includes(:customer, :sender, :recipient, carrier_product: [:carrier], advanced_prices: [:advanced_price_line_items])
        .find_not_exported_company_shipments(company_id: @company_id)
        .order(created_at: :desc)
    end

    def find_updated
      @updated = Shipment
        .includes(:customer, :sender, :recipient, carrier_product: [:carrier], advanced_prices: [:advanced_price_line_items])
        .find_updated_and_exported_company_shipments(company_id: @company_id)
        .order(created_at: :desc)
    end

    def set_exported
      ids = (@not_exported + @updated).map(&:id)
      ShipmentExport.set_company_exported(company_id: @company_id, shipment_ids: ids)
    end

end
