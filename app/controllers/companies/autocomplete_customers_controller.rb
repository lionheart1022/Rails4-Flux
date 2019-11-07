class Companies::AutocompleteCustomersController < CompaniesController
  def index
    customer_list = CompanyDashboard::CustomerList.new(current_company: current_company)
    customer_list.type = :search
    customer_list.search_term = params[:term]

    render json: customer_list.to_builder.target!
  end
end
