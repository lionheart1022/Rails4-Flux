class Companies::EconomicCarriersController < CompaniesController
  def index
    if current_company.economic_v2_access?
      @carriers =
        Carrier
        .find_enabled_company_carriers(company_id: current_company.id)
        .includes(:carrier)
        .sort_by { |c| c.owner_carrier.company_id }

      render :index
    else
      render :missing_access
    end
  end

  private

  def set_current_nav
    @current_nav = "economic_v2"
  end
end
