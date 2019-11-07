class FedExTrackingLib < TrackingLib
  API_ENDPOINT = '/web-services'

  attr_reader :api_host

  def initialize(faraday_connection: nil, api_host: nil)
    @connection = faraday_connection
    @api_host = api_host
  end

  def track(credentials: nil, awb: nil)
    tracking_request_xml = TrackingRequest.new(awb, credentials).request

    fed_ex_tracking_response = post_tracking_request(tracking_request_xml)
    tracking_response = TrackingResponse.new(fed_ex_tracking_response.body, awb)

    if tracking_response.success?
      tracking_response.trackings
    else
      if Rails.env.development? || Rails.env.test?
        raise TrackingLib::Errors::TrackingFailedException.new(
          code: tracking_response.error_code,
          description: tracking_response.error_message
        )
      else
        ExceptionMonitoring.report_message("FedEx Tracking Error", context: {
          awb: awb,
          error_code: tracking_response.error_code,
          error_message: tracking_response.error_message,
        })
        nil
      end
    end
  end

  private

  def post_tracking_request(tracking_request_xml)
    connection.post do |req|
      req.url(API_ENDPOINT)
      req.body = tracking_request_xml
    end
  end

  def connection
    @connection ||= build_connection
  end

  def build_connection
    Faraday.new(:url => api_host) do |conn|
      conn.use FaradayMiddleware::FollowRedirects
      conn.request  :url_encoded
      conn.response :logger
      conn.adapter  Faraday.default_adapter
    end
  end
end
