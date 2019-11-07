class Companies::CarrierProductCustomerBillingConfigurationsController < CompaniesController
  def show
    @carrier_product_customer = current_company.find_carrier_product_customer(params[:carrier_product_customer_id])
    @carrier_product_customer_recording = current_company.find_carrier_product_customer_recording(@carrier_product_customer)
  end

  def update
    @carrier_product_customer = current_company.find_carrier_product_customer(params[:carrier_product_customer_id])
    @carrier_product_customer_recording = current_company.find_carrier_product_customer_recording(@carrier_product_customer)
    CustomerBillingConfiguration.update_for_customer_recording(@carrier_product_customer_recording, params: configuration_params)

    redirect_to companies_carrier_product_customer_billing_configuration_path(@carrier_product_customer)
  end

  private

  def set_current_nav
    @current_nav = "carrier_product_customers"
  end

  def configuration_params
    params.fetch(:billing_configuration, {}).permit(
      :enabled,
      :day_interval,
      :with_detailed_pricing,
    )
  end
end
