class ApplicationController < ActionController::Base
  include UserAccessResolving

  add_flash_types :success, :error
  protect_from_forgery with: :exception

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || begin
      resolver = UserAccessResolver.new(resource, host: request.host)
      resolver.perform!

      if resolver.access_to_single_customer?
        customers_shipments_path(current_customer_identifier: resolver.current_customer_identifier)
      elsif resolver.access_to_single_company?
        companies_dashboard_path
      else
        account_selector_path
      end
    end
  end
end
