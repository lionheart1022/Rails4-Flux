class Companies::CustomerCarriersController < CompaniesController
  def index
    @view_model = ::Companies::CustomerCarrierListView.new(current_company: current_company, customer_id: params[:customer_id])
    @customer = @view_model.customer
  end

  def show
    @view_model = ::Companies::CustomerCarrierShowView.new(current_company: current_company, customer_id: params[:customer_id], carrier_id: params[:id])
    @customer = @view_model.customer
    @carrier = @view_model.carrier
  end

  private

  def set_current_nav
    @current_nav = "customers"
  end
end
