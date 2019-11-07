class Companies::FerryRoutesController < CompaniesController
  def index
    @ferry_routes = FerryRoute.for_company(current_company)
  end

  private

  def set_current_nav
    @current_nav = "ferry_routes"
  end
end
