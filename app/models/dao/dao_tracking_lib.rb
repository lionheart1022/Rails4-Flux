class DAOTrackingLib
  module Responses
    SUCCESS = 'OK'
  end

  Credentials = Struct.new(:account, :password)

  attr_reader :shipment
  attr_reader :credentials

  def initialize(shipment)
    @shipment = shipment
    carrier_product_credentials = shipment.carrier_product.get_credentials
    @credentials = Credentials.new(carrier_product_credentials[:account], carrier_product_credentials[:password])
    @connection = Faraday.new(url: API_HOST, timeout: 60, open_timeout: 60) do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
  end

  API_HOST = 'https://api.dao.as'
  API_TRACKNTRACE_V1 = '/TrackNTrace_v1.php'

  def track
    return if credentials.blank? || shipment.awb.blank?

    req_params = URI.encode_www_form(
      "kundeid" => credentials.account,
      "kode" => credentials.password,
      "stregkode" => shipment.awb,
    )

    req_uri = URI(API_TRACKNTRACE_V1)
    req_uri.query = req_params

    track_response = @connection.get do |req|
      req.url(req_uri.to_s)
    end

    track_response_body = track_response.body
    track_json = JSON.parse(track_response_body)
    successful = track_json["status"] == DAOTrackingLib::Responses::SUCCESS

    if successful
      extract_trackings(body: track_json)
    else
      code = track_json["fejlkode"]
      description = track_json["fejltekst"]
      ExceptionMonitoring.report_message("DAO tracking failed.", context: { code: code, description: description, awb: shipment.awb })
      []
    end
  end

  private

  def extract_trackings(body:)
    events = body["resultat"]["haendelser"]

    events.map do |event|
      time_string = event["tidspunkt"]
      event_time = time_string.to_time
      event_code = event["haendelse"]
      description_string = event["beskrivelse"]
      event_place = event["sted"]
      place_string = "- place: #{event_place}" if event_place.present?
      event_description = "#{description_string} - code: #{event_code} #{place_string}"

      DAOTracking.new(
        status: parse_status(event_code),
        event_time: event_time,
        description: event_description
      )
    end
  end

  def parse_status(event_code)
    shipment.carrier_product.dao_tracking_status_map[event_code]
  end
end
