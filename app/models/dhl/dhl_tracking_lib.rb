class DHLTrackingLib < TrackingLib

  module Codes
    module Responses
      SUCCESS = 'success'
    end

    module States
      PROGRESS    = 'progress'
      COMPLETIOMN = 'completion'
      EXCEPTION   = 'exception'
    end
  end

  class Credentials
    attr_reader :company, :password, :account

    def initialize(company: nil, password: nil, account: nil)
      @company  = company
      @password = password
      @account  = account
    end
  end

  API_TEST_HOST = 'https://xmlpitest-ea.dhl.com/'
  API_PROD_HOST = 'https://xmlpi-ea.dhl.com/'
  API_ENDPOINT  = '/XMLShippingServlet'

  def initialize
    host = Rails.env.production? ? API_PROD_HOST : API_TEST_HOST

    @connection = Faraday.new(:url => host, timeout: 60, open_timeout: 60) do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
  end

  def track(credentials: nil, awb: nil)
    return if credentials.blank? || awb.blank?

    tracking_request_xml = load_xml(filename: 'dhl_tracking_template.xml.erb', binding: binding)
    Rails.logger.debug tracking_request_xml

    begin
      response = @connection.post do |req|
        req.url(API_ENDPOINT)
        req.body = tracking_request_xml
      end
    rescue => e
      Rails.logger.debug "DHLTrackingError: #{e.inspect}"
      raise DHLTrackingLib::Errors::ConnectionFailedException.new
    end

    response_body = response.body
    check_error(response_body)
    Rails.logger.debug response_body

    trackings = extract_trackings(response: response_body)
    return trackings
  rescue => e
    Rails.logger.error "DHLTrackingError #{e.inspect}"
    return []
  end

  private

    def extract_trackings(response: nil)
      doc             = Nokogiri::XML(response)
      response_status = doc.xpath('//Status/ActionStatus').text

      trackings = doc.xpath('//ShipmentInfo/ShipmentEvent').map do |event|
        date_string       = event.xpath('./Date').text
        time_string       = event.xpath('./Time').text
        event_date        = parse_date(date_string)
        event_time        = parse_time(date_string, time_string)

        event_code        = event.xpath('./ServiceEvent/EventCode').text.try(:downcase)
        status            = parse_status(event_code)
        event_description = event.xpath('./ServiceEvent/Description').text
        further_details   = event.xpath('./EventRemarks/FurtherDetails').text
        next_steps        = event.xpath('./EventRemarks/NextSteps').text

        event_description = [event_description, further_details].join(". ") if further_details.present?
        event_description = [event_description, next_steps].join(". ") if next_steps.present?

        service_area_code        = event.xpath('./ServiceArea//ServiceAreaCode').text
        service_area_description = event.xpath('./ServiceArea/Description').text

        event_city, event_country = service_area_description.split(' - ')

        signatory = fix_encoding(event.xpath('./Signatory').text)

        tracking = Tracking.build_tracking(
          type: DHLTracking.to_s,
          status: status,
          description: event_description,
          signatory: signatory,
          event_date: event_date,
          event_time: event_time,
          event_city: event_city,
          event_country: event_country,
        )

        tracking
      end
      Rails.logger.debug "DHL trackings: #{trackings}"
      return trackings
    end

    def parse_status(status_code)
      if progress_codes.include?(status_code)
        TrackingLib::States::IN_TRANSIT
      elsif completion_codes.include?(status_code)
        TrackingLib::States::DELIVERED
      elsif exception_codes.include?(status_code)
        TrackingLib::States::EXCEPTION
      end
    end

    def check_error(response)
      doc         = Nokogiri::XML(response)
      code        = doc.xpath('//Condition/ConditionCode').text
      description = doc.xpath('//Condition/ConditionData').text

      error_is_present = code.present? && description.present?
      raise TrackingLib::Errors::TrackingFailedException.new(code: code, description: description) if error_is_present
    end

    def parse_date(date)
      return if date.blank?

      date = date.split('-')

      year   = date[0].to_i
      month  = date[1].to_i
      day    = date[2].to_i

      Date.new(year, month, day)
    end

    def parse_time(date, time)
      return if date.blank? || time.blank?

      date = date.split('-')
      time = time.split(':')

      year   = date[0].to_i
      month  = date[1].to_i
      day    = date[2].to_i

      hours   = time[0].to_i
      minutes = time[1].to_i

      DateTime.new(year, month, day, hours, minutes)
    end

    def progress_codes
      %w[ad af ar bl bn cc ci cr cu df es fd hi ho ic pd pl po pu rr rw sa si sm st tr wc]
    end

    def completion_codes
      %w[br cs dd ds ok rt sp tp]
    end

    def exception_codes
      %w[ba ca cd cm dm hp ia ir mc md ms na nd nh oh rd sc td ud]
    end

    def fix_encoding(s)
      return if s.nil?

      out_s = s.dup
      out_s.force_encoding("BINARY")
      f = proc do |c|
        if c.bytes == [140]
          "?"
        elsif c.bytes.length == 1
          c.bytes.pack("U")
        end
      end

      out_s.encode("UTF-8", fallback: f)
    end
end
