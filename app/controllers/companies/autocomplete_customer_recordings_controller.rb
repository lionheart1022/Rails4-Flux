class Companies::AutocompleteCustomerRecordingsController < CompaniesController
  def index
    @customer_recordings =
      CustomerRecording
      .where(company: current_company)
      .enabled
      .autocomplete_search(customer_name: params[:term])
      .order(:id)
      .page(params[:page])
      .per(5)

    request.variant = :select2 if params[:variant] == "select2"

    respond_to do |format|
      format.json.select2
      format.json.none { render json: { status: "not_implemented_yet" } }
    end
  end
end
