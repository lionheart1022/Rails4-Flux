class Companies::CustomerBillingConfigurationsController < CompaniesController
  def show
    @customer = current_company.find_customer(params[:customer_id])
    @customer_recording = current_company.find_customer_recording(@customer)
  end

  def update
    @customer = current_company.find_customer(params[:customer_id])
    @customer_recording = current_company.find_customer_recording(@customer)

    CustomerBillingConfiguration.update_for_customer_recording(@customer_recording, params: configuration_params)

    redirect_to companies_customer_billing_configuration_path(@customer)
  end

  private

  def set_current_nav
    @current_nav = "customers"
  end

  def configuration_params
    params.fetch(:billing_configuration, {}).permit(
      :enabled,
      :day_interval,
      :with_detailed_pricing,
    )
  end
end
