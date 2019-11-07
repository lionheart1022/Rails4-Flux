# API documentation for Unifaun/Creating Shipments can be found at https://api.unifaun.com/rs-docs/##creating_shipments

class UnifaunShipmentHTTPRequest
  CREATE_SHIPMENT_API_URI = URI("https://api.unifaun.com/rs-extapi/v1/shipments")
  STORED_SHIPMENT_API_URI = URI("https://api.unifaun.com/rs-extapi/v1/stored-shipments")
  TEST_DEFAULT = !Rails.env.production?

  attr_accessor :shipment
  attr_accessor :test
  attr_reader :request_body

  def initialize(shipment, test: TEST_DEFAULT)
    self.shipment = shipment
    self.test = test
  end

  def book_shipment!(uri: CREATE_SHIPMENT_API_URI)
    @request_body = UnifaunShipmentHTTPRequestBody.new(shipment, test: test).to_json

    response =
      connection.post do |req|
        req.url uri
        req.body = @request_body
        req.headers["Content-Type"] = "application/json"
      end

    UnifaunShipmentHTTPResponse.parse!(response, connection: connection)
  end

  # This extra method is really just used for testing.
  def perform_store_shipment_request!(uri: STORED_SHIPMENT_API_URI)
    @request_body = UnifaunShipmentHTTPRequestBody.new(shipment, test: test).to_json(variant: :store_shipment)

    # We don't do parsing here as the returned response will just be tested.
    connection.post do |req|
      req.url uri
      req.body = @request_body
      req.headers["Content-Type"] = "application/json"
    end
  end

  def connection
    @connection ||= begin
      Faraday.new do |conn|
        conn.use FaradayMiddleware::FollowRedirects
        conn.request :url_encoded
        conn.response :logger
        conn.adapter Faraday.default_adapter
        conn.basic_auth(*basic_auth_args)
      end
    end
  end

  private

  def basic_auth_args
    credentials = shipment.carrier_product.get_credentials

    [
      credentials[:id], # username
      credentials[:secret], # password
    ]
  end
end
