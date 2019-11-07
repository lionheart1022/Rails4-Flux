class Companies::CustomerDangerousGoodsController < CompaniesController
  def create
    customer = Customer.where(company: current_company).find(params[:customer_id])
    customer.enable_dangerous_goods!

    redirect_to settings_companies_customer_path(customer)
  end

  def destroy
    customer = Customer.where(company: current_company).find(params[:customer_id])
    customer.disable_dangerous_goods!

    redirect_to settings_companies_customer_path(customer)
  end
end
