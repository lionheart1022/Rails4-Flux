class Companies::AutobookingRequestsController < CompaniesController
  def index
    @filter = AutobookRequestFilter.for_company(current_company, params: filter_params)
    @filter.perform!
  end

  def show
    request = CarrierProductAutobookRequest.find(params[:id])
    redirect_to companies_shipment_autobook_request_path(request.shipment_id, request.id)
  end

  private

  def filter_params
    {
      customer_id: params[:filter_customer_id],
      state: params[:filter_state],
      grouping: params[:grouping],
      sorting: params[:sorting],
      pagination: true,
      page: params[:page],
    }
  end
end
