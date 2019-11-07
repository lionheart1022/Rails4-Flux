# API documentation for GLS Web API can be found at http://api.gls.dk/ws

class GLSShipmentHTTPRequest
  API_URI = URI("http://api.gls.dk/ws/DK/V1/CreateShipment")

  attr_accessor :shipment
  attr_accessor :parcelshop_id
  attr_accessor :test
  attr_accessor :uri
  attr_reader :request_body

  def initialize(shipment, uri: API_URI)
    # Defaults
    self.test = false
    self.parcelshop_id = nil

    self.shipment = shipment
    self.uri = uri
  end

  def book_shipment!
    @request_body = build_request_body.to_json

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri, { "Content-Type" => "application/json" })
    request.body = @request_body

    response = http.request(request)

    GLSShipmentHTTPResponse.parse!(response)
  end

  private

  def build_request_body
    GLSShipmentHTTPRequestBody.new(shipment).tap do |body|
      body.parcelshop_id = parcelshop_id
      body.test = test
    end
  end
end
