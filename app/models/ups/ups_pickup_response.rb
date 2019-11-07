class UPSPickupResponse
  def self.parse(response_body)
    response = JSON.parse(response_body)

    if response["PickupCreationResponse"]
      r = SuccessResponse.new(response)

      if r.error?
        ExceptionMonitoring.report_message("[UPS Pickup] Valid (but unknown) response", context: { response_body: response_body })
      end

      r
    elsif response["Fault"]
      ErrorResponse.new(response)
    else
      ExceptionMonitoring.report_message("[UPS Pickup] Unknown response", context: { response_body: response_body })
      UnknownResponse.new(response)
    end
  end

  class BaseResponse
    attr_reader :response_hash

    def initialize(response_hash)
      @response_hash = response_hash
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
      "Error response from UPS [#{error_code}]: #{error_description}"
    end

    private

    def error_code
      primary_error_code_part.try(:[], "Code")
    end

    def error_description
      primary_error_code_part.try(:[], "Description")
    end

    def primary_error_code_part
      response_hash["Fault"]
        .try(:[], "detail")
        .try(:[], "Errors")
        .try(:[], "ErrorDetail")
        .try(:[], "PrimaryErrorCode")
    end
  end

  class SuccessResponse < BaseResponse
    def success?
      status_code == "1"
    end

    def error?
      !success?
    end

    def success_message
      "Successful response from UPS with PRN #{pickup_request_number}"
    end

    def error_message
      "Unsuccessful response from UPS with status code #{status_code.inspect}"
    end

    def pickup_request_number
      response_hash["PickupCreationResponse"].try(:[], "PRN")
    end

    private

    def status_code
      @_status_code ||= response_hash["PickupCreationResponse"]["Response"]["ResponseStatus"]["Code"]
    end
  end

  class UnknownResponse < BaseResponse
    def error?
      true
    end

    def error_message
      "Unknown response from UPS"
    end
  end
end
