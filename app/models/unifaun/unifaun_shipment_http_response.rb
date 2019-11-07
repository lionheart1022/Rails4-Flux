module UnifaunShipmentHTTPResponse
  class << self
    def parse!(response, connection:)
      case response.status
      when 201
        SuccessResponse.new(response, connection: connection)
      when 401
        raise UnauthorizedError.new("Unauthorized to create Unifaun booking", response: response)
      when 422
        raise ParameterError.new("Unifaun booking error (status: #{response.status})", response: response)
      else
        raise UnknownError.new("Unexpected Unifaun booking error (status: #{response.status})", response: response)
      end
    end
  end

  class SuccessResponse
    attr_reader :http_response, :body

    def initialize(http_response, connection:)
      @http_response = http_response
      @connection = connection
      @body = JSON.parse(http_response.body)
    end

    def awb_no
      first_shipment["parcels"].first.try(:[], "parcelNo") || first_shipment["id"]
    end

    def pdf_url
      first_shipment["pdfs"].first["href"]
    end

    def generate_temporary_awb_pdf_file(&block)
      pdf_response = @connection.get(pdf_url)

      begin
        tmp_file = Tempfile.new([awb_no || "UNKNOWN_AWB_NO", ".pdf"])
        tmp_file.binmode
        tmp_file.write(pdf_response.body)
        tmp_file.rewind

        yield tmp_file.path
      ensure
        tmp_file.close
        tmp_file.unlink
      end
    end

    private

    def first_shipment
      body.first
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

    def as_shipment_errors
      json_body.map do |error_hash|
        code = error_hash["messageCode"]
        field = error_hash["field"]
        message = error_hash["message"]

        Shipment::Errors::GenericError.new(code: code, description: "#{field}: #{message}")
      end
    end
  end

  class UnauthorizedError < BaseError
    def as_shipment_errors
      [Shipment::Errors::GenericError.new(code: "INVALID", description: "Credentials invalid/missing")]
    end
  end

  class UnknownError < BaseError
  end
end
