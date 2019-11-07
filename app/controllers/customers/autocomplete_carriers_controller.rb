class Customers::AutocompleteCarriersController < CustomersController
  def index
    carrier_list = ::CarrierFilter.new(context: current_context)

    if params[:term].present?
      carrier_list.type = :search
      carrier_list.search_term = params[:term]
    else
      carrier_list.type = :all
    end

    request.variant = :select2 if params[:variant] == "select2"

    respond_to do |format|
      format.json.select2 { @nest_builder = carrier_list.to_builder }
      format.json.none { render json: carrier_list.to_builder.target! }
    end
  end
end
