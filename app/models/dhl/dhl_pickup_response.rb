class DHLPickupResponse
  def self.parse(response_body)
    doc = Nokogiri::XML(response_body)

    if doc.root.name == "ErrorResponse"
      ErrorResponse.new(doc)
    elsif doc.root.name == "PickupErrorResponse"
      ErrorResponse.new(doc)
    elsif doc.root.name == "BookPUResponse"
      r = ValidBookPUResponse.new(doc)

      if r.error?
        ExceptionMonitoring.report_message("[DHL Pickup] Valid (but unknown) response", context: { response_body: response_body })
      end

      r
    else
      ExceptionMonitoring.report_message("[DHL Pickup] Unknown response", context: { response_body: response_body })
      UnknownResponse.new(doc)
    end
  end

  class BaseResponse
    attr_reader :doc

    def initialize(doc)
      @doc = doc
    end

    def error?
      false
    end

    def success?
      false
    end
  end

  class ErrorResponse < BaseResponse
    def error?
      true
    end

    def error_message
      "Error response from DHL [#{condition_code}]: #{condition_data}"
    end

    def condition_code
      doc.at_xpath("//Status/Condition/ConditionCode")
    end

    def condition_data
      doc.at_xpath("//Status/Condition/ConditionCode")
    end
  end

  class ValidBookPUResponse < BaseResponse
    def success?
      confirmation_number.present?
    end

    def error?
      !success?
    end

    def success_message
      "Successful response from DHL with confirmation number #{confirmation_number}"
    end

    def error_message
      "Unknown response from DHL"
    end

    def confirmation_number
      @confirmation_number ||= doc.at_xpath("//ConfirmationNumber").try(:text)
    end
  end

  class UnknownResponse < BaseResponse
    def error?
      true
    end

    def error_message
      "Unknown response from DHL"
    end
  end
end
