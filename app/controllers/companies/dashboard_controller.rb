class Companies::DashboardController < CompaniesController
  def index
    filter = CompanyDashboardFilter.new(predefined_period: "all_time")
    filter.current_company = current_company

    if Rails.env.development? && ["1", "true"].include?(params[:dummy].to_s)
      filter.fetch_dummy_stats!
    else
      filter.fetch_stats!
    end

    @view_model = Companies::DashboardView.new_from_filter(filter)
    @view_model.current_company = current_company

    @carrier_list = CompanyDashboard::CarrierList.new(current_company: current_company)
    @customer_list = CompanyDashboard::CustomerList.new(current_company: current_company)
  end

  private

  def set_current_nav
    @current_nav = "dashboard"
  end

  def set_body_class_for_company
    set_body_class("companies_dashboard")
  end
end
