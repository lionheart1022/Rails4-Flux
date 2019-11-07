class API::V1::Customers::ShipmentPricesController < API::V1::Customers::CustomersController
  around_action :tag_logger_with_access_token

  def create
    interactor = ShipmentPriceCatalog.new_from_api(current_company: current_company, current_customer: current_customer, params: shipment_params)
    interactor.perform!

    if interactor.success?
      @price_catalog = interactor.result
      render
    elsif interactor.catalog_params.errors.any?
      render json: { error_type: "validation_error", errors: interactor.catalog_params.errors }, status: :bad_request
    else
      render json: { error_type: "internal_error" }, status: :internal_server_error
    end
  end

  private

  def shipment_params
    root_params = ActionController::Parameters.new(shipment: JSON.parse(request.body.read))

    shipment_params = root_params.fetch(:shipment, {}).permit(
      :shipment_type,
      :default_sender,
      :sender => [
        :address_line1,
        :address_line2,
        :address_line3,
        :zip_code,
        :city,
        :country_code,
        :state_code,
      ],
      :recipient => [
        :address_line1,
        :address_line2,
        :address_line3,
        :zip_code,
        :city,
        :country_code,
        :state_code,
      ],
      :package_dimensions => [
        :amount,
        :height,
        :length,
        :weight,
        :width,
      ]
    )

    shipment_params
  end

  def tag_logger_with_access_token
    tag = { "company" => current_company.id, "customer" => current_customer.id, "token" => @token.id }.to_json
    Rails.logger.tagged("AccessToken = #{tag}") { yield }
  end
end
