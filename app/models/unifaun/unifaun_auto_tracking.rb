module UnifaunAutoTracking
  BASE_URI = URI("https://api2.postnord.com/rest/shipment/v2/trackandtrace/findByIdentifier.json")

  class BaseError < StandardError; end
  class ResponseServerError < BaseError; end
  class BlankAWBError < BaseError; end
  class UnexpectedResponseBody < BaseError
    attr_reader :original_exception
    attr_reader :body

    def initialize(msg, original_exception: nil, body: nil)
      @original_exception = original_exception
      @body = body
      super(msg)
    end
  end

  class << self
    def track_shipment(awb:)
      raise BlankAWBError if awb.blank?

      uri = BASE_URI.dup
      uri.query = URI.encode_www_form(
        "apikey" => ENV.fetch("POSTNORD_API_KEY"),
        "id" => awb,
      )

      res = Net::HTTP.get_response(uri)

      if res.is_a?(Net::HTTPSuccess)
        response_body_to_trackings(json: JSON.parse(res.body))
      elsif res.is_a?(Net::HTTPServerError)
        raise ResponseServerError
      else
        res.value # Raises an HTTP error if the response is not 2xx (success).
      end
    end

    def response_body_to_trackings(json:)
      TrackAndTraceResponse.new(json).trackings
    end
  end

  class TrackAndTraceResponse
    attr_reader :body

    def initialize(body)
      @body = body
    end

    def trackings
      return [] if body["TrackingInformationResponse"]["shipments"].blank?

      item = nil

      # Multi-package shipments will contain multiple items;
      # for tracking purposes we will just use the data from the first item/package.
      begin
        item = body["TrackingInformationResponse"]["shipments"][0]["items"][0]
      rescue => e
        raise UnexpectedResponseBody.new("Error while fetching TrackingInformationResponse.shipments.0.items.0", original_exception: e, body: body)
      end

      events = item["events"]

      events.map do |event_attrs|
        event = TrackAndTraceEvent.new(item: item, event_attrs: event_attrs)
        UnifaunTracking.new(event.build_tracking_attrs)
      end
    end
  end

  class TrackAndTraceEvent
    attr_reader :item
    attr_reader :attrs

    def initialize(item:, event_attrs:)
      @item = item
      @attrs = event_attrs
    end

    def build_tracking_attrs
      {
        status: tracking_status,
        description: pretty_description,
        event_time: parsed_event_time,
        event_date: parsed_event_time.to_date,
        event_city: attrs["location"].try(:[], "city"),
        event_country: attrs["location"].try(:[], "country"),
        event_zip_code: attrs["location"].try(:[], "postcode"),
        expected_delivery_date: parsed_estimated_date_of_arrival,
        expected_delivery_time: parsed_estimated_time_of_arrival,
      }
    end

    def parsed_event_time
      Time.zone.parse(attrs["eventTime"])
    end

    def parsed_estimated_date_of_arrival
      parsed_estimated_time_of_arrival ? parsed_estimated_time_of_arrival.to_date : nil
    end

    def parsed_estimated_time_of_arrival
      if item["estimatedTimeOfArrival"].present?
        Time.zone.parse(item["estimatedTimeOfArrival"])
      end
    end

    def tracking_status
      if progress_codes.include?(attrs["status"])
        TrackingLib::States::IN_TRANSIT
      elsif completion_codes.include?(attrs["status"])
        TrackingLib::States::DELIVERED
      elsif exception_codes.include?(attrs["status"])
        TrackingLib::States::EXCEPTION
      end
    end

    def pretty_description
      String(attrs["eventDescription"]) + (tracking_status ? "" : " [status: #{attrs['status']}, code: #{attrs['eventCode']}]")
    end

    # The possible values for status can be found in the docs at https://developer.postnord.com/docs#!/shipment-v2-trackandtrace/findByIdentifier
    # Here's the list as of Feb 13th, 2017.
    # status (string, optional) = ['CREATED' or 'AVAILABLE_FOR_DELIVERY' or 'DELAYED' or 'DELIVERED' or 'DELIVERY_IMPOSSIBLE' or 'DELIVERY_REFUSED' or 'EXPECTED_DELAY' or 'INFORMED' or 'EN_ROUTE' or 'OTHER' or 'RETURNED' or 'STOPPED' or 'SPLIT'],
    #
    # Some values of status are ignored, such as CREATED, INFORMED, etc. as they don't map to our internal 3 states.

    def progress_codes
      %w[
        EN_ROUTE
        AVAILABLE_FOR_DELIVERY
        DELAYED
        EXPECTED_DELAY
      ]
    end

    def completion_codes
      %w[
        DELIVERED
      ]
    end

    def exception_codes
      %w[
        DELIVERY_IMPOSSIBLE
        DELIVERY_REFUSED
        RETURNED
        STOPPED
      ]
    end
  end
end
