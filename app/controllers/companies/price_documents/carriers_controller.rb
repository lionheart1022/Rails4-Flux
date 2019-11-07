class Companies::PriceDocuments::CarriersController < CompaniesController
  def index
    @carriers =
      Carrier
      .find_enabled_company_carriers(company_id: current_company.id)
      .includes(:carrier)
      .sort { |a, b|
        if a.owner_carrier.company_id == b.owner_carrier.company_id
          a.name.to_s.strip.casecmp(b.name.to_s.strip)
        else
          a.owner_carrier.company_id <=> b.owner_carrier.company_id
        end
      }
  end

  def show
    @carrier =
      ::Carrier
      .find_enabled_company_carriers(company_id: current_company.id)
      .find(params[:id])

    @carrier_products =
      ::CarrierProduct
      .find_enabled_company_carrier_products(company_id: current_company.id, carrier_id: @carrier.id)
      .sort_by { |p| p.name.downcase }

    @view_model = Companies::CarrierProductPriceDocumentOverview.new(current_company: current_company, carrier_products: @carrier_products)
  end

  private

  def set_current_nav
    @current_nav = "price_documents"
  end
end
