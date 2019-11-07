class TrackingLib
  ABSTRACT_CLASS = 'abstract_class'

  module Errors
    class TrackingLibException < StandardError
      attr_reader :code, :description, :data

      def initialize(code: nil, description: nil, data: nil)
        @code        = code
        @description = description
        @data        = data
      end

    end

    class TrackingFailedException < TrackingLibException
    end

    class ConnectionFailedException < TrackingLibException
    end

    class InvalidCredentials < TrackingLibException
    end

    class IncompleteInformation < TrackingLibException
    end

    module Codes
      MISSING_AWB = 'missing_awb'
    end

  end

  module States
    IN_TRANSIT      = 'in_transit'
    DELIVERED       = 'delivered'
    EXCEPTION       = 'exception'
  end

  module Types
    UPS = 'ups'
    TNT = 'tnt'
    DAO = 'dao'
  end

  class << self
    def tracked_shipment_states
      [
        Shipment::States::BOOKED,
        Shipment::States::IN_TRANSIT,
        Shipment::States::PROBLEM
      ]
    end
  end

  def initialize(host: nil)
    @connection = Faraday.new(:url => host, timeout: 60, open_timeout: 60) do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
  end

  def track
    raise TrackingLib::Errors::TrackingLibException.new(code: BookingLib::Errors::ABSTRACT_CLASS, description: "Abstract class. Not implemented")
  end

  private

  def load_xml(filename: nil, binding: nil)
    path = File.join(Rails.root, 'app', 'models', 'templates', filename)
    xml_template = ERB.new(File.read(path))
    xml_template.result(binding)
  end

end
