class GLSTrackingLib < TrackingLib

  API_HOST     = 'http://www.gls-group.eu:80'
  API_ENDPOINT = '/276-I-PORTAL-WEBSERVICE/services/Tracking'

  def initialize
    super(host: API_HOST)
  end

  class Credentials
    attr_reader :username, :password

    def initialize(username: nil, password: nil)
      @username = username
      @password = password
    end
  end

  def track(credentials: nil, awb: nil)

    if !credentials.present?
      raise GLSTrackingLib::Errors::InvalidCredentials.new
    end

    if awb.blank?
      raise GLSTrackingLib::Errors::IncompleteInformation.new(code: TrackingLib::Errors::Codes::MISSING_AWB)
    end

    tracking_request_xml = load_xml(filename: 'gls_tracking_template.xml.erb', binding: binding)

    begin
      response = @connection.post do |req|
        req.url(API_ENDPOINT)
        req.body = tracking_request_xml
        req.headers['Content-Type'] = 'application/xml'
        req.headers['SOAPAction'] = 'urn:createShipmentDD'
      end
    rescue => e
      ExceptionMonitoring.report(e, context: { awb: awb })
      return nil
    end

    response_body = response.body
    doc = init_nokogiri(response_body: response_body)

    error_code_node = doc.at_xpath('//ErrorCode')
    if error_code_node && error_code_node.text == "998"
      # <p793:ExitCode>
      #   <p793:ErrorCode>998</p793:ErrorCode>
      #   <p793:ErrorDscr>No data found</p793:ErrorDscr>
      # </p793:ExitCode>
      #
      # We have a bunch of old GLS shipments which we cannot track probably because the shipment was booked and later not sent.
      # We'll log information about these and manually handle them.

      Rails.logger.tagged("GLSTracking.NoDataFound") do
        Rails.logger.error "awb=#{awb}"
      end

      # Return early so we don't report exception later on
      return nil
    end

    if !is_succesful?(nokogiri: doc)
      error = parse_error(nokogiri: doc)
      raise error
    end

    trackings = extract_trackings(nokogiri: doc)

    Rails.logger.info "\nTRACKIGNS:: #{trackings.inspect}"

    return trackings
  rescue => exception
    ExceptionMonitoring.report(exception, context: { awb: awb, response: response_body })
    return nil
  end

  private

    def init_nokogiri(response_body: nil)
      doc = Nokogiri::XML(response_body)
      doc.remove_namespaces!

      doc
    end

    def parse_error(nokogiri: nil)
      code = nokogiri.xpath('//ErrorCode').text
      description = nokogiri.xpath('//ErrorDscr').text

      error = TrackingLib::Errors::TrackingFailedException.new(code: code, description: description)
      return error
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

    def extract_trackings(nokogiri: nil)
      trackings = nokogiri.xpath('//History').map do |doc|
        location_name = doc.xpath('./LocationName').text
        location_code = doc.xpath('./LocationCode').text
        country_name  = doc.xpath('./CountryName').text
        status_code   = doc.xpath('./Code').text
        description   = doc.xpath('./Desc').text

        year    = doc.xpath('./Date/Year').text.to_i
        month   = doc.xpath('./Date/Month').text.to_i
        day     = doc.xpath('./Date/Day').text.to_i
        hours   = doc.xpath('./Date/Hour').text.to_i
        minutes = doc.xpath('./Date/Minut').text.to_i

        event_date = Date.new(year, month, day)
        event_time = DateTime.new(year, month, day, hours, minutes)

        status = parse_status(status_code)

        Tracking.build_tracking(
          type: 'GLSTracking',
          status: status,
          description: description,
          event_date: event_date,
          event_time: event_time,
          event_country: country_name,
          event_city: location_name,
          depot_name: location_code
        )
      end
    end

    def is_succesful?(nokogiri: nil)
      nokogiri.xpath('//ErrorCode').text == '0'
    end

    def progress_codes
      %w[
        1.0 1.58 1.79 2.0 2.29 2.79 2.98 2.101 2.106 2.107 2.124 2.235 2.240 2.286 2.360 2.379 6.13 6.14 6.211 7.56
        7.57 8.0 8.27 8.80 8.83 8.168 8.169 8.908 11.0 11.256 12.9 13.0 13.64 15.0 15.65 15.150 15.261 16.0 17.0 27.1010
        27.1011 71.0 81.0
      ]
    end

    def completion_codes
      %w[3.0 3.120 3.121 3.122 3.124 3.130 3.131 3.142 3.165 3.872 3.887 3.96]
    end

    def exception_codes
      %w[
        4.1 4.24 4.25 4.26 4.30 4.31 4.32 4.33 4.37 4.38 4.40 4.41 4.42 4.43 4.44 4.47 4.48 4.55 4.63 4.66 4.69 4.80
        4.86 4.119 4.126 4.128 4.129 4.149 4.152 4.170 4.207 4.208 4.209 4.701 4.897 4.898 4.899 5.0 8.32 8.41 8.63
        8.126 8.149 8.152 8.327 8.328 12.30 12.32 12.33 12.37 12.41 12.42 12.63 12.69 12.72 12.80 12.83 12.149 12.152
        12.170 14.46 14.53 14.60 14.61 14.62 14.63 14.66 14.68 14.69 14.70 14.72 14.76 14.149 14.162 14.163 14.164 14.166
        14.313 14.314 14.359 14.397 14.398 14.464 14.908 14.914 14.939 14.989 18.32 18.41 19.32 19.37 19.40 19.41 19.42 19.71
        19.74 19.75 30.40 30.41 30.42 31.30 31.31 31.32 31.33 31.40 31.41 31.42 31.72 31.74 31.75 35.1 35.10 35.24 35.25 35.26
        35.30 35.32 35.37 35.38 35.40 35.41 35.47 35.48 35.63 35.72 35.73 35.74 35.75 35.80 35.83 35.86 35.119 35.126 35.128
        35.149 35.152 35.170 35.207 35.208 35.209 35.253 35.701 35.897 35.898 35.899 82.37 82.40 82.41 82.71 82.74 82.700
        82.897 941.0 941.31 941.480
      ]
    end

end
