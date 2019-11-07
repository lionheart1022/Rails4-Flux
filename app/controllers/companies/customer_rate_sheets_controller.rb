class Companies::CustomerRateSheetsController < CompaniesController
  def create
    interactor = Companies::CreateCustomerRateSheet.new(current_company: current_company, current_user: current_user, customer_id: params[:customer_id], customer_carrier_product_id: params[:customer_carrier_product_id])

    begin
      interactor.perform!
    rescue Companies::CreateCustomerRateSheet::Error => e
      flash[:error] = e.message
      redirect_to companies_customer_carrier_path(interactor.customer, interactor.carrier_product.carrier)
    else
      redirect_to url_for(action: "show", id: interactor.rate_sheet.id)
    end
  end

  def show
    customer = current_company.customers.find(params[:customer_id])
    @rate_sheet = customer.find_rate_sheet_by_id(params[:id])

    render
  end

  def print
    customer = current_company.customers.find(params[:customer_id])
    @rate_sheet = customer.find_rate_sheet_by_id(params[:id])

    render "admin/rate_sheets/print", layout: "print"
  end

  private

  def set_current_nav
    @current_nav = "customers"
  end
end
