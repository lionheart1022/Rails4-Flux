class Companies::ShipmentSearchController < CompaniesController
  def index
    shipment_search = ShipmentSearch.new(query: params[:search].try(:[], :query))
    shipment_search.current_company = current_company
    shipment_search.pagination = true
    shipment_search.page = params[:page]
    shipment_search.mode = params[:search].try(:[], :mode)
    shipment_search.perform_search!

    if shipment_search.matches_single_shipment?
      @view_model = search_result_shipment_view(shipment_search.shipment)
      render :show
    else
      @view_model = shipment_search
      render :index
    end
  end

  private

  def search_result_shipment_view(shipment)
    ShipmentViewFactory.view_for_search(shipment, current_company: current_company)
  end

  def set_current_nav
    @current_nav = "shipments_search"
  end
end
