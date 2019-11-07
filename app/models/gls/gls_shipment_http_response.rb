# > HTTP Return codes
# > 2XX - The API call was successful.
# > 4XX - The API call had an error in the parameters. The error will be encoded in the body of the response.
# > 5XX - The API call was unsuccessful. Contact GLS support +45 76221245
#
# Source: http://api.gls.dk/ws

module GLSShipmentHTTPResponse
  class << self
    def parse!(response)
      if response.is_a?(Net::HTTPSuccess)
        SuccessResponse.new(response)
      elsif response.is_a?(Net::HTTPClientError)
        raise ParameterError.new("The API call had an error in the parameters", response: response)
      else
        raise UnknownError.new("The API call was unsuccessful", response: response)
      end
    end
  end

  class SuccessResponse
    attr_reader :http_response, :body

    def initialize(http_response)
      @http_response = http_response
      @body = JSON.parse(http_response.body)
    end

    def awb_no
      body["ConsignmentId"]
    end

    def parcels
      body["Parcels"]
    end

    def base64_encoded_pdf
      body["PDF"]
    end

    def base64_decoded_pdf
      Base64.decode64(base64_encoded_pdf)
    end

    def generate_temporary_awb_pdf_file(&block)
      tmp_file = Tempfile.new([awb_no || "UNKNOWN_AWB_NO", ".pdf"])
      tmp_file.binmode
      tmp_file.write(base64_decoded_pdf)
      tmp_file.rewind

      yield tmp_file.path
    ensure
      tmp_file.close
      tmp_file.unlink
    end
  end

  class BaseError < StandardError
    attr_reader :response

    def initialize(msg, response:)
      @response = response
      super(msg)
    end
  end

  class ParameterError < BaseError
    def json_body
      @_json_body ||= JSON.parse(response.body)
    end

    def response_error_message
      joined_model_state_error_messages || json_body["Message"]
    end

    def response_error_code
      return @_response_error_code if defined?(@_response_error_code)

      match = response_error_message.match(/\((?<code>T[^\)]+)\)\b?\z/) if response_error_message
      @_response_error_code = match ? match[:code] : nil
    end

    private

    def joined_model_state_error_messages
      return nil if json_body["ModelState"].blank?

      json_body["ModelState"]
        .flat_map { |_field, messages| Array(messages) }
        .join("\n")
    end
  end

  class UnknownError < BaseError
  end
end
