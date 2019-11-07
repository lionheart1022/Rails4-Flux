module APIV1ForCustomers
  class ShipmentsController < APIV1ForCustomersController
    def create
      api_params = ShipmentAPIParams.new(root_params: params.to_unsafe_h.with_indifferent_access, current_customer: current_customer)

      validator = ::API::V1::Customers::Shipments::Shipment.new(
        company_id: current_company.id,
        customer_id: current_customer.id,
        shipment_data: api_params.shipment_data,
        sender_data: api_params.sender_data,
        recipient_data: api_params.recipient_data,
        pickup_data: api_params.pickup_data,
        token: @token,
        callback_url: api_params.callback_url,
      )

      begin
        validator.check_defaults
      rescue APIRequestError => error
        render json: { status: APIRequest::Statuses::FAILED, errors: [{ code: error.code, description: error.message }] }, status: 500
        return
      rescue => e
        ExceptionMonitoring.report!(e)
        render json: { status: APIRequest::Statuses::FAILED, errors: [{ code: "-", description: "Internal Server Error" }] }, status: 500
        return
      end

      shipment_params = build_shipment_params(api_params)
      creator = ShipmentCreatorForAPI.new(current_context: current_context, shipment_params: shipment_params)
      success = creator.perform

      if success
        shipment = creator.shipment
        api_request = creator.api_request

        json = {
          unique_shipment_id: shipment.unique_shipment_id,
          request_id: api_request.unique_id,
          status: shipment.state,
          callback_url: api_request.callback_url,
        }

        render json: json, status: :ok
      else
        render json: { status: APIRequest::Statuses::FAILED, errors: [{ code: "-", description: "Unexpected Error" }] }, status: 500
      end
    end

    def update
      unique_shipment_id = params[:unique_shipment_id].try(:strip)
      shipment = Shipment.find_customer_shipment_from_unique_shipment_id(company_id: current_company.id, customer_id: current_customer.id, unique_shipment_id: unique_shipment_id)

      api_params = ShipmentAPIParams.new(root_params: params.to_unsafe_h.with_indifferent_access, current_customer: current_customer)

      validator = ::API::V1::Customers::Shipments::Shipment.new(
        company_id: current_company.id,
        customer_id: current_customer.id,
        shipment_data: api_params.shipment_data,
        sender_data: api_params.sender_data,
        recipient_data: api_params.recipient_data,
        pickup_data: api_params.pickup_data,
        token: @token,
        callback_url: api_params.callback_url,
      )

      begin
        validator.check_defaults

        if shipment.nil?
          raise APIRequestError.new(code: APIRequestError::Codes::SHIPMENT_MISSING_OR_NOT_FOUND, message: APIRequestError::Messages::SHIPMENT_MISSING_OR_NOT_FOUND)
        end

        if shipment.state != Shipment::States::BOOKING_FAILED
          raise APIRequestError.new(code: APIRequestError::Codes::CANNOT_RETRY_ALREADY_BOOKED, message: APIRequestError::Messages::CANNOT_RETRY_ALREADY_BOOKED)
        end
      rescue APIRequestError => error
        render json: { status: APIRequest::Statuses::FAILED, errors: [{ code: error.code, description: error.message }] }, status: 500
        return
      rescue => e
        ExceptionMonitoring.report!(e)
        render json: { status: APIRequest::Statuses::FAILED, errors: [{ code: "-", description: "Internal Server Error" }] }, status: 500
        return
      end

      shipment_params = build_shipment_params(api_params)
      updater = ShipmentUpdaterForAPI.new(current_context: current_context, shipment: shipment, shipment_params: shipment_params)
      success = updater.perform

      if success
        shipment = updater.shipment
        api_request = updater.api_request

        json = {
          unique_shipment_id: shipment.unique_shipment_id,
          request_id: api_request.unique_id,
          status: shipment.state,
          callback_url: api_request.callback_url,
        }

        render json: json, status: :ok
      else
        render json: { status: APIRequest::Statuses::FAILED, errors: [{ code: "-", description: "Unexpected Error" }] }, status: 500
      end
    end

    private

    def build_shipment_params(api_params)
      shipment_params = {}.with_indifferent_access
      shipment_params.merge!(api_params.shipment_data)
      shipment_params.delete(:product_code)

      shipment_params[:carrier_product_id] = find_carrier_product.id
      shipment_params[:sender_attributes] = api_params.sender_data
      shipment_params[:recipient_attributes] = api_params.recipient_data
      shipment_params[:request_pickup] = api_params.request_pickup?
      shipment_params[:pickup_options] = api_params.pickup_data
      shipment_params[:callback_url] = api_params.callback_url

      shipment_params
    end

    def find_carrier_product
      CarrierProduct.find_enabled_customer_carrier_product_from_product_code(customer_id: current_customer.id, product_code: params[:shipment][:product_code])
    end
  end
end
