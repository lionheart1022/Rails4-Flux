class Customers::RateSheetsController < CustomersController
  def index
    @carrier_products =
      current_customer
      .carrier_products_with_active_rate_sheets
      .sort_by(&:name)
  end

  def print
    @rate_sheet = current_customer.latest_active_rate_sheet_for(carrier_product_id: params[:id])

    if @rate_sheet.nil?
      flash[:error] = "Could not find the rate sheet you requested"
      redirect_to url_for(action: "index")
      return
    end

    render "admin/rate_sheets/print", layout: "print"
  end

  private

  def set_current_nav
    @current_nav = "rate_sheets"
  end
end
