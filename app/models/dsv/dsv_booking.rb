class DSVBooking
  attr_reader :shipment
  attr_reader :test

  class << self
    def perform!(*args)
      new(*args).perform!
    end
  end

  def initialize(shipment, test: true)
    @shipment = shipment
    @test = test
  end

  def perform!
    raise ArgumentError, "Shipment must be persisted" unless shipment.persisted?

    register_packages!

    awb = generate_awb
    shipment.awb = awb

    label = DSVLabel.build(shipment: shipment, package_sscc_mapping: package_sscc_mapping)
    message = DSVBookingMessage.new(shipment, awb, test: test)
    transfer = DSVBookingTransfer.new(message: message, file_name: "CargoFlux_#{awb}.txt")
    transfer.perform!

    BookingResult.new(awb: awb, label: label)
  end

  private

  attr_reader :package_sscc_mapping

  def register_packages!
    # We cannot (easily) support editing a shipment because we need to register the packages with their associated SSCC number.
    # When we start considering status for DSV bookings we'll need to revisit this part here:
    #   A simple way to get around the issue is to delete already registered package records and just create new ones.
    raise ArgumentError, "Packages are already registered for this shipment" if DSVPackage.where(shipment: shipment).exists?

    @package_sscc_mapping = {}

    ActiveRecord::Base.transaction do
      shipment.package_dimensions.dimensions.each_with_index do |dimension, index|
        package_identifier = GS1NumberSeries.next_sscc_number!

        @package_sscc_mapping[index] = package_identifier

        DSVPackage.create!(
          shipment: shipment,
          unique_identifier: package_identifier,
          package_index: index,
          metadata: {},
        )
      end
    end
  end

  def generate_awb
    # TODO: Check with DSV if this is OK
    "CF#{shipment.unique_shipment_id.gsub('-', 'X')}"
  end

  class BookingResult
    attr_reader :awb
    attr_reader :label

    def initialize(awb:, label:)
      @awb = awb
      @label = label
    end

    def generate_temporary_awb_pdf_file(&block)
      label.with_tempfile(&block)
    end
  end
end
