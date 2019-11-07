class UPSTrackingLib < TrackingLib

  module States
    PICKUP          = 'pickup'
    MANIFEST_PICKUP = 'manifest_pickup'
  end

  module Descriptions
    IN_TRANSIT      = 'UPS: In transit'
    DELIVERED       = 'UPS: Shipment has been delivered'
    EXCEPTION       = 'UPS: A problem has been reported by the carrier'
    PICKUP          = 'UPS: Shipment has been picked up'
    MANIFEST_PICKUP = 'UPS: Manifest has been picked up'
  end

  class Credentials
    attr_reader :access_token, :company, :password

    def initialize(access_token: nil, company: nil, password: nil)
      @access_token    = access_token
      @company         = company
      @password        = password
    end

    def specified?
      access_token.present? && company.present? && password.present?
    end
  end

  API_HOST     = 'https://wwwcie.ups.com'
  API_ENDPOINT = '/ups.app/xml/Track'

  def initialize
    super(host: API_HOST)
  end

  def track(credentials: nil, awb: nil)

    if !credentials.specified?
      raise UPSTrackingLib::Errors::InvalidCredentials.new
    end

    if awb.blank?
      raise UPSTrackingLib::Errors::IncompleteInformation.new(code: TrackingLib::Errors::Codes::MISSING_AWB)
    end

    tracking_request_xml = load_xml(filename: 'ups_tracking_template.xml.erb', binding: binding)

    begin
      response = @connection.post do |req|
        req.url(API_ENDPOINT)
        req.body = tracking_request_xml
      end
    rescue => e
      raise UPSTrackingLib::Errors::ConnectionFailedException.new(description: e.message)
    end

    response_body = response.body
    if error_is_present?(response: response_body)
      error = parse_error(response: response_body)
      Rails.logger.debug error.description
      raise error
    end

    tracking = extract_tracking(response: response_body)

    # we should return an array of trackings for compatability
    trackings = [tracking]

    return trackings
  rescue => exception
    Rails.logger.error "TrackingResponseError: #{exception.inspect}"
    ExceptionMonitoring.report(exception) if exception.is_a?(UPSTrackingLib::Errors::ConnectionFailedException)

    return nil
  end

  private

    def extract_tracking(response: nil)
      doc      = Nokogiri::XML(response)

      expected_delivery_date = doc.at_xpath('//ScheduledDeliveryDate/text()').try(:text)
      expected_delivery_date = parse_date(date: expected_delivery_date)

      signatory  = fix_encoding(doc.at_xpath('//SignedForByName/text()').try(:text))

      date       = doc.at_xpath('//Activity/Date/text()').try(:text)
      time       = doc.at_xpath('//Activity/Time/text()').try(:text)
      event_date = parse_date(date: date)
      event_time = parse_time(date: date, time: time)

      country  = doc.at_xpath('//ActivityLocation/Address/CountryCode/text()').try(:text)
      city     = fix_encoding(doc.at_xpath('//ActivityLocation/Address/City/text()').try(:text))
      zip_code = doc.at_xpath('//ActivityLocation/Address/PostalCode/text()').try(:text)

      status      = doc.at_xpath('//Status/StatusType/Code/text()').try(:text)
      status      = parse_status(status: status)
      description = fix_encoding(doc.at_xpath('//Status/StatusType/Description/text()').try(:text))

      tracking = Tracking.build_tracking(
        type: 'UPSTracking',
        status: status,
        description: description,
        signatory: signatory,
        event_date: event_date,
        event_time: event_time,
        expected_delivery_date: expected_delivery_date,
        event_country: country,
        event_city: city,
        event_zip_code: zip_code
      )

      return tracking
    end

    def error_is_present?(response: nil)
      doc = Nokogiri::XML(response)
      doc.xpath('/TrackResponse/Response/Error/ErrorCode').first.present?
    end

    def parse_error(response: nil)
      doc         = Nokogiri::XML(response)
      code        = doc.xpath('TrackResponse/Response/Error/ErrorCode').first.content.to_s
      description = doc.xpath('TrackResponse/Response/Error/ErrorDescription').first.content.to_s

      error = TrackingLib::Errors::TrackingFailedException.new(code: code, description: description)
      return error
    end

    def parse_status(status: nil)
      case status
        when 'I'
          TrackingLib::States::IN_TRANSIT
        when 'D'
          TrackingLib::States::DELIVERED
        when 'X'
          TrackingLib::States::EXCEPTION
        when 'P'
          UPSTrackingLib::States::PICKUP
        when 'M'
          UPSTrackingLib::States::MANIFEST_PICKUP
        end
    end

    def description(status: nil)
      case status
        when TrackingLib::States::IN_TRANSIT
          UPSTrackingLib::Descriptions::IN_TRANSIT
        when TrackingLib::States::DELIVERED
          UPSTrackingLib::Descriptions::DELIVERED
        when TrackingLib::States::EXCEPTION
          UPSTrackingLib::Descriptions::EXCEPTION
        when UPSTrackingLib::States::PICKUP
          UPSTrackingLib::Descriptions::PICKUP
        when UPSTrackingLib::States::MANIFEST_PICKUP
          UPSTrackingLib::Descriptions::MANIFEST_PICKUP
        end
    end

    def parse_date(date: nil)
      return if date.nil?
      Rails.logger.debug date

      year   = date[0..3].to_i
      month  = date[4..5].to_i
      day    = date[6..7].to_i

      Date.new(year, month, day)
    end

    def parse_time(date: nil, time: nil)
      return if date.nil? || time.nil?

      year   = date[0..3].to_i
      month  = date[4..5].to_i
      day    = date[6..7].to_i

      hours   = time[0..1].to_i
      minutes = time[2..3].to_i
      seconds = time[4..5].to_i

      Time.new(year, month, day, hours, minutes, seconds)
    end

    def fix_encoding(s)
      return if s.nil?

      out_s = s.dup
      out_s.force_encoding("BINARY")
      f = proc do |c|
        # This fallback function handles the case where an UTF-8 character has been encoded in the unicode codepoint.
        #
        # This issue was first seen with the city "OSKARSTRöM".
        #   In the response this was encoded as "OSKARSTR\xf6M". "\xf6" is the unicode codepoint for "ö" but it is an invalid UTF-8 character.
        #   Instead the codepoint maps to "\xc3\xb6" in utf-8.
        #
        # TODO: Maybe this is not a problem in a newer version of their API, we should look into it.
        if c.bytes.length == 1
          c.bytes.pack("U")
        end
      end

      out_s.encode("UTF-8", fallback: f)
    end
end
