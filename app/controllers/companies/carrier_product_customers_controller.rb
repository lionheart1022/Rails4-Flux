class Companies::CarrierProductCustomersController < CompaniesController

  def update_economic
    company_id = current_company.id
    company_customer_id = params[:id]
    number = params[:entity_relation][:external_accounting_number]
    Company.update_external_accounting_number(company_id: company_id, company_customer_id: company_customer_id, number: number)

    flash[:success] = 'Succesfully updated external account number'
    redirect_to companies_carrier_product_customer_carrier_product_customer_carriers_path(company_customer_id)
  end

  private

  def set_current_nav
    @current_nav = "carrier_product_customers"
  end

end
