class Companies::CustomerRecordingsController < CompaniesController
  def index
    @customer_recordings = current_company.customer_recordings.enabled.in_order.page(params[:page])
  end

  private

  def set_current_nav
    @current_nav = "customer_recordings"
  end
end
