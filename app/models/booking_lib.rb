require 'rexml/document'

class BookingLib

  module Errors
    ABSTRACT_CLASS = 'abstract_class'

    INVALID_ARGUMENT      = 'invalid_argument'
    CREATE_BOOKING_FAILED = 'create_booking_failed'
    SHIP_BOOKING_FAILED   = 'ship_booking_failed'
    UNKNOWN_ERROR         = 'unknown_error'
    FILE_ERROR            = 'file_error'
    PARCEL_SHOP_NOT_FOUND = 'parcel_shop_not_found'
    BOOKING_FAILED        = 'booking_failed'

    class BookingLibException < StandardError
      attr_reader :error_code, :errors, :data

      def initialize(error_code: nil, errors: nil, data: nil)
        @error_code = error_code
        @errors     = errors
        @data       = data
      end

      def human_friendly_text
        error_texts = []
        error_texts << "Exception: #{self.class.to_s}"
        error_texts << "Error code: #{exception.error_code}" unless exception.error_code.nil?
        error_texts << "Errors:\n#{exception.errors.join("\n")}" unless exception.errors.nil?
        error_texts << "Error data:\n#{exception.data}" unless exception.data.nil?
        error_text = error_texts.join("\n\n")

        return error_text
      end
    end

    # Is raised if API connection fails prematuraly due to for example invalid credentials
    #
    class RuntimeException < BookingLibException
      attr_reader :error_code, :description, :data

      def initialize(error_code: nil, description: nil, data: nil)
        @description = description

        super(error_code: error_code, data: data)
      end

      def human_friendly_text
        error_texts = []
        error_texts << "Exception: #{self.class.to_s}"
        error_texts << "Error code: #{exception.error_code}" unless exception.error_code.nil?
        error_texts << "Description: #{exception.description}" unless exception.description.nil?
        error_texts << "Error data:\n#{exception.data}" unless exception.data.nil?
        error_text = error_texts.join("\n\n")

        return error_text
      end
    end

    class BookingFailedException < BookingLibException
    end

    class AwbDocumentFailedException < BookingLibException
    end

    class ConsignmentNoteFailedException < BookingLibException
    end

    class RemoveTemporaryFilesFailedException < BookingLibException
    end

    class APIError
      attr_reader :code, :description, :severity

      def initialize(code: nil, description: nil, severity: nil)
        @code         = code
        @description  = description
        @severity     = severity
      end

      def to_s
        string = "#{@code}: #{@description}"
        string + " (severity: #{severity})" if severity
      end
    end
  end

  class Booking
    attr_reader :awb, :awb_file_path, :consignment_note_file_path, :warnings

    def initialize(awb: nil, awb_file_path: nil, consignment_note_file_path: nil, warnings: nil)
      @awb                        = awb
      @awb_file_path              = awb_file_path
      @consignment_note_file_path = consignment_note_file_path
      @warnings                   = warnings
    end
  end

  def error_context(request, response)
    "Response:\n#{response}\n\nRequest:\n#{request}"
  end

  def path_to_template(filename: nil)
    File.join(Rails.root, 'app', 'models', 'templates', filename)
  end

  def book_shipment(shipment: nil, sender: nil, recipient: nil, shipping_options: nil)
    raise BookingLib::Errors::BookingFailedException.new(error_code: BookingLib::Errors::ABSTRACT_CLASS), "Abstract class. Not implemented"
  end

  def get_awb_document(booking: nil)
    raise BookingLib::Errors::AwbDocumentFailedException.new(error_code: BookingLib::Errors::ABSTRACT_CLASS), "Abstract class. Not implemented"
  end

  def remove_temporary_files(booking)
    Rails.logger.debug "INSDE"
    Rails.logger.debug booking.inspect

    File.delete(booking.awb_file_path) unless booking.awb_file_path.nil?
    File.delete(booking.consignment_note_file_path) unless booking.consignment_note_file_path.nil?

  rescue => exception
    ExceptionMonitoring.report(exception)
    raise BookingLib::Errors::RemoveTemporaryFilesFailedException.new
  end

  def transform_charset(string)
    return '' if !string.present?

    transliterated_string = I18n.transliterate(string)
    escaped_string        = xml_escape(transliterated_string)

    escaped_string
  end

  private

    def xml_escape(string)
      REXML::Text.new(string, false, nil, false).to_s
    end

end
