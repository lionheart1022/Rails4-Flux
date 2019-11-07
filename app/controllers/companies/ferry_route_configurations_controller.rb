class Companies::FerryRouteConfigurationsController < CompaniesController
  before_action :set_ferry_route

  def show
    @ferry_route_configuration = @ferry_route.configuration
    render :edit
  end

  def update
    @ferry_route_configuration = @ferry_route.build_configuration(ferry_route_configuration_params)

    if @ferry_route.save_configuration(@ferry_route_configuration)
      redirect_to companies_ferry_routes_path
    else
      render :edit
    end
  end

  private

  def set_ferry_route
    @ferry_route = current_company.find_ferry_route(params[:ferry_route_id])
  end

  def ferry_route_configuration_params
    params.fetch(:ferry_route_configuration, {}).permit(
      :account_number,
      :scandlines_id,
      :sftp_host,
      :sftp_user,
      :sftp_password,
      :carrier_product_id,
    )
  end

  def set_current_nav
    @current_nav = "ferry_routes"
  end
end
