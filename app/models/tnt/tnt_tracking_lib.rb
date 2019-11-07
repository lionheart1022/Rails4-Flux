class TNTTrackingLib < TrackingLib

  module StateCodes
    EXCEPTION  = 'EXC'
    DELIVERED  = 'DEL'
    IN_TRANSIT = 'INT'
  end

  class Credentials
    attr_reader :company, :password

    def initialize(company: nil, password: nil)
      @company  = company
      @password = password
    end
  end

  API_HOST      = 'https://express.tnt.com'
  API_ENDPOINT  = '/expressconnect/track.do'

  def initialize
    @connection = Faraday.new(:url => API_HOST, timeout: 60, open_timeout: 60) do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
  end

  def track(credentials: nil, awb: nil)
    return if credentials.blank? || awb.blank?

    Rails.logger.debug awb
    tracking_request_xml = load_xml(filename: 'tnt_tracking_template.xml.erb', binding: binding)

    authenticate(credentials: credentials, connection: @connection)
    begin
      response = @connection.post do |req|
        req.url(API_ENDPOINT)
        req.body = 'xml_in=' + tracking_request_xml
      end
    rescue => e
      Rails.logger.debug "TNTTrackingError: #{e.inspect}"
      raise TNTTrackingLib::Errors::ConnectionFailedException.new
    end

    response_body = response.body
    Rails.logger.debug response_body

    raise TNTTrackingLib::Errors::InvalidCredentials.new(data: { awb: awb, credentials: credentials })      if !request_was_authorized?(response: response_body)
    raise TNTTrackingLib::Errors::TrackingFailedException.new(data: { awb: awb, credentials: credentials }) if access_is_public?(response: response_body)

    trackings = extract_trackings(response: response_body)
    return trackings
  rescue => e
    Rails.logger.error "TNTTrackingError #{e.inspect}"
    Rails.logger.error "TNTTrackingError_AWB #{awb.inspect}"
    return []
  end

  private

    def authenticate(credentials: nil, connection: nil)
      connection.basic_auth(credentials.company, credentials.password)
    end

    def extract_trackings(response: nil)
      doc       = Nokogiri::XML(response)

      expected_delivery_date_string = doc.xpath('/TrackResponse/Consignment/DeliveryDate/text()').try(:text)
      expected_delivery_time_string = doc.xpath('/TrackResponse/Consignment/DeliveryTime/text()').try(:text)

      expected_delivery_date = parse_date(date: expected_delivery_date_string)
      expected_delivery_time = parse_time(date: expected_delivery_date_string, time: expected_delivery_time_string)

      signatory   = doc.xpath('/TrackResponse/Consignment/Signatory/text()').try(:text)
      status_code = doc.xpath('/TrackResponse/Consignment/SummaryCode/text()').try(:text)
      status      = parse_status(status: status_code)

      trackings = doc.xpath('/TrackResponse/Consignment/StatusData').map do |event|
        status_description = event.xpath('./StatusDescription/text()').try(:text)

        depot_name = event.xpath('./DepotName/text()').try(:text)

        date_string = event.xpath('./LocalEventDate/text()').try(:text)
        time_string = event.xpath('./LocalEventTime/text()').try(:text)
        event_date  = parse_date(date: date_string)
        event_time  = parse_time(date: date_string, time: time_string)

        tracking = Tracking.build_tracking(
          type: 'TNTTracking',
          status: status,
          description: status_description,
          signatory: signatory,
          expected_delivery_date: expected_delivery_date,
          expected_delivery_time: expected_delivery_time,
          event_date: event_date,
          event_time: event_time,
          depot_name: depot_name
        )

        tracking
      end
      Rails.logger.debug "TNT trackings: #{trackings}"
      return trackings
    end

    def parse_status(status: nil)
      case status
        when TNTTrackingLib::StateCodes::DELIVERED
          TrackingLib::States::DELIVERED
        when TNTTrackingLib::StateCodes::IN_TRANSIT
          TrackingLib::States::IN_TRANSIT
        when TNTTrackingLib::StateCodes::EXCEPTION
          TrackingLib::States::IN_TRANSIT
        end
    end

    def access_is_public?(response: nil)
      doc    = Nokogiri::XML(response)
      access = doc.xpath('/TrackResponse/Consignment').attr('access').value
      access == 'public'
    end

    # If authorization fails, TNT responses with an HTML string
    #
    def request_was_authorized?(response: nil)
      (response =~ /<HTML>/).nil? ? true : false
    end

    def parse_error(response: nil)
      doc         = Nokogiri::XML(response)
      code        = doc.xpath('TrackResponse/Response/Error/ErrorCode').first.content.to_s
      description = doc.xpath('TrackResponse/Response/Error/ErrorDescription').first.content.to_s

      error = TrackingLib::Errors::TrackingFailedException.new(code: code, description: description)
      return error
    end

    def parse_date(date: nil)
      return if date.blank?

      year   = date[0..3].to_i
      month  = date[4..5].to_i
      day    = date[6..7].to_i

      Date.new(year, month, day)
    end

    def parse_time(date: nil, time: nil)
      return if date.blank? || time.blank?

      year   = date[0..3].to_i
      month  = date[4..5].to_i
      day    = date[6..7].to_i

      hours   = time[0..1].to_i
      minutes = time[2..3].to_i

      DateTime.new(year, month, day, hours, minutes)
    end

end
