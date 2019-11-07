class API::V1::Customers::AddressImportsController < API::V1::Customers::CustomersController
  def create
    interactor = ::Customers::CreateAddressImport.new(current_customer: current_customer)
    interactor.file = params[:file]

    result = interactor.run!

    render json: result.json_response, status: result.http_status
  end
end
