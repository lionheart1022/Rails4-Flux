class Companies::CustomerDetailedPricingController < CompaniesController
  def create
    customer = Customer.where(company: current_company).find(params[:customer_id])
    customer.update!(show_detailed_prices: true)

    redirect_to settings_companies_customer_path(customer)
  end

  def destroy
    customer = Customer.where(company: current_company).find(params[:customer_id])
    customer.update!(show_detailed_prices: false)

    redirect_to settings_companies_customer_path(customer)
  end
end
