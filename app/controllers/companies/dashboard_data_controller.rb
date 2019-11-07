class Companies::DashboardDataController < CompaniesController
  def index
    filter_params = params.slice(:predefined_period, :custom_period_from, :custom_period_to, :customer_id, :company_customer_id, :carrier_id).permit!
    filter = CompanyDashboardFilter.new(filter_params)
    filter.current_company = current_company

    if Rails.env.development? && ["1", "true"].include?(params[:dummy].to_s)
      sleep 2 # Add some fake delay
      filter.fetch_dummy_stats!
    else
      filter.fetch_stats!
    end

    @view_model = Companies::DashboardView.new_from_filter(filter)

    render json: @view_model.to_builder.target!
  end
end
