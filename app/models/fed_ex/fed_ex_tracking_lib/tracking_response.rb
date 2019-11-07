class FedExTrackingLib
  class TrackingResponse
    Error = Struct.new(:code, :message)

    delegate :code, :message, to: :error, allow_nil: true, prefix: true

    attr_reader :response_body, :awb

    def initialize(response_body, awb)
      @response_body = response_body
      @awb           = awb
    end

    def trackings
      tracking_events.map do |event|
        event_time = Time.parse(event.xpath("Timestamp/text()").to_s)
        Tracking.build_tracking(
          type: FedExTracking.to_s,
          status: parse_status(event.xpath("EventType/text()").to_s),
          description: event.xpath("EventDescription/text()").to_s,
          event_time: event_time,
          event_date: event_time.to_date,
          event_city: event.xpath("Address/City/text()").to_s,
          event_country: event.xpath("Address/CountryName/text()").to_s,
          event_zip_code: event.xpath("Address/PostalCode/text()").to_s
        )
      end
    end

    def success?
      !error.present?
    end

    def error
      severity = reply_doc.xpath("//TrackDetails/Notification/Severity/text()").to_s
      message = reply_doc.xpath("//TrackDetails/Notification/Message/text()").to_s
      code = reply_doc.xpath("//TrackDetails/Notification/Code/text()").to_s
      if severity.present? && severity != "SUCCESS"
        Error.new(code, message)
      end
    end

    private

    def parse_status(status_code)
      if progress_codes.include?(status_code)
        TrackingLib::States::IN_TRANSIT
      elsif completion_codes.include?(status_code)
        TrackingLib::States::DELIVERED
      elsif exception_codes.include?(status_code)
        TrackingLib::States::EXCEPTION
      end
    end

    def progress_codes
      %w[
        AA AC AD AF AP AR AX CA CH DP DR DS EA ED EP FD HL IT IX LO OD OF OX
        PF PL PM PU PX RR RM RC RS RP LP RG RD SE SF SP TR CC CD CP EA SP CA SH
        CU BR TP SP
      ]
    end

    def completion_codes
      %w[DL RC]
    end

    def exception_codes
      %w[DD DE DL DY EO PD SE]
    end

    def tracking_events
      reply_doc.xpath("//TrackDetails").find do |track_details|
        track_details.xpath("TrackingNumber/text()").to_s == awb
      end.xpath("Events")
    end

    def reply_doc
      @docs ||= parse_xml.xpath("//TrackReply")
    end

    def parse_xml
      Nokogiri::XML(response_body).tap do |doc|
        doc.remove_namespaces!
      end
    end
  end
end
