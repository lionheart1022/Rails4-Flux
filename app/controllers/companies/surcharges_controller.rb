class Companies::SurchargesController < CompaniesController
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

  private

  def set_current_nav
    @current_nav = "carrier_surcharges"
  end
end
