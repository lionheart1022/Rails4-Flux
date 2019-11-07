class Companies::AutocompleteDirectCustomersController < CompaniesController
  def index
    @customers =
      Customer
      .autocomplete_search(company_id: current_company.id, customer_name: params[:term])
      .includes(:address)
      .order(:id)
      .page(params[:page])
      .per(5)

    request.variant = :select2 if params[:variant] == "select2"

    respond_to do |format|
      format.json.select2
      format.json.none
    end
  end
end
