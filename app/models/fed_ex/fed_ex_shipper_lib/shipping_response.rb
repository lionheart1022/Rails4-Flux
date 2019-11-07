class FedExShipperLib
  class ShippingResponse
    ERROR_SEVERITIES = ["ERROR", "FAILURE"].freeze

    attr_reader :response_body, :unique_shipment_id

    delegate :combined_awb_pdf, to: :temp_pdf_label

    def initialize(response_body, unique_shipment_id)
      @response_body = response_body
      @unique_shipment_id = unique_shipment_id
    end

    def success?
      !ERROR_SEVERITIES.include?(reply_doc.xpath("//HighestSeverity/text()").to_s)
    end

    def warnings_and_notes
      notifications.select do |error|
        ["WARNING", "NOTE"].include?(error.severity)
      end
    end

    def errors
      notifications.select do |error|
        ERROR_SEVERITIES.include?(error.severity)
      end
    end

    def awb
      reply_doc.xpath("//CompletedShipmentDetail/MasterTrackingId/TrackingNumber/text()").to_s.presence
    end

    private

    def temp_pdf_label
      TempPdfLabel.new(unique_shipment_id, label_image_blobs)
    end

    def notifications
      reply_doc.xpath("Notifications").map do |notification_element|
        BookingLib::Errors::APIError.new(
          severity: notification_element.xpath("Severity/text()").to_s,
          code: notification_element.xpath("Code/text()").to_s,
          description: notification_element.xpath("Message/text()").to_s
        )
      end
    end

    def label_image_blobs
      reply_doc.xpath("//CompletedPackageDetails/Label/Parts/Image/text()").map(&:to_s)
    end

    def reply_doc
      @doc ||= parse_xml.xpath("//CreateOpenShipmentReply")
    end

    def parse_xml
      Nokogiri::XML(response_body).tap do |doc|
        doc.remove_namespaces!
      end
    end
  end
end
