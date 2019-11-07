class Companies::AutocompleteCarriersController < CompaniesController
  def index
    carrier_list = CompanyDashboard::CarrierList.new(current_company: current_company)
    carrier_list.type = :search
    carrier_list.search_term = params[:term]

    request.variant = :select2 if params[:variant] == "select2"

    respond_to do |format|
      format.json.select2 { @nest_builder = carrier_list.to_builder }
      format.json.none { render json: carrier_list.to_builder.target! }
    end
  end
end
