class AdminHomeController < AdminController
  # GET /admin
  def index
    resolver = UserAccessResolver.new(current_user, host: request.host)
    resolver.perform!

    if resolver.access_to_single_customer?
      redirect_to customers_shipments_path(current_customer_identifier: resolver.current_customer_identifier)
    elsif resolver.access_to_single_company?
      redirect_to companies_dashboard_path
    else
      redirect_to account_selector_path
    end
  end
end
