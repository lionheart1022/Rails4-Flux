class KHTBooking
  attr_reader :shipment
  attr_reader :message
  attr_reader :waybill_number

  class << self
    def perform!(*args)
      new(*args).perform!
    end
  end

  def initialize(shipment)
    # This will create a duplicate object and make sure the passed in shipment was persisted.
    @shipment = Shipment.find(shipment.id)
  end

  def perform!
    register_waybill!
    register_packages!

    @message = KHTMessage.new(
      shipment: shipment,
      waybill_number: waybill_number,
      track_trace_number: track_trace_number,
      credentials: message_credentials,
      test_booking: test_booking?,
    )

    label = KHTLabel.build(
      shipment: shipment,
      package_barcode_number_mapping: package_barcode_number_mapping,
      track_trace_number: track_trace_number,
      waybill_number: waybill_number,
      customer_number: customer_number,
      terminal_number: KHTMessage::TERMINAL_NR,
    )

    if test_booking?
      Rails.logger.tagged("KHTTransfer(test)") do
        Rails.logger.info "*" * 80
        Rails.logger.info message.to_xml
        Rails.logger.info "*" * 80
      end
    else
      KHTTransfer.perform!(
        message: message,
        ftp_user: carrier_product_credentials[:ftp_user],
        ftp_host: carrier_product_credentials[:ftp_host],
        ftp_password: carrier_product_credentials[:ftp_password],
        file_name: "CargoFlux_#{track_trace_number}.xml",
      )
    end

    BookingResult.new(awb: track_trace_number, label: label)
  end

  private

  def test_booking?
    customer_carrier_product.test
  end

  def customer_carrier_product
    @customer_carrier_product ||= CustomerCarrierProduct.find_by!(customer_id: shipment.customer_id, carrier_product_id: shipment.carrier_product_id)
  end

  def carrier_product_credentials
    @carrier_product_credentials ||= shipment.carrier_product.get_credentials
  end

  def message_credentials
    OpenStruct.new(sender_id: sender_id, customer_number: customer_number)
  end

  def sender_id
    carrier_product_credentials[:sender_id]
  end

  def customer_number
    carrier_product_credentials[:customer_number].to_s.rjust(8, '0')
  end

  def register_waybill!
    @waybill_number = KHTNumberSeries.next_waybill_number!
  end

  def track_trace_number
    "#{@waybill_number}#{customer_number}#{KHTMessage::TERMINAL_NR}"
  end

  def register_packages!
    # We cannot (easily) support editing a shipment because we need to register the packages with their associated SSCC number.
    # When we start considering status for KHT bookings we'll need to revisit this part here:
    #   A simple way to get around the issue is to delete already registered package records and just create new ones.
    raise ArgumentError, "Packages are already registered for this shipment" if KHTPackage.where(shipment: shipment).exists?

    ActiveRecord::Base.transaction do
      shipment.package_dimensions.dimensions.each_with_index do |dimension, index|
        package_number = index + 1
        package_identifier = "#{track_trace_number}#{package_number.to_s.rjust(4, '0')}"

        KHTPackage.create!(shipment: shipment, unique_identifier: package_identifier, package_index: index, metadata: {})
      end
    end
  end

  def package_barcode_number_mapping
    Hash[KHTPackage.where(shipment: shipment).group_by(&:package_index).map { |key, packages| [key, packages.first.unique_identifier] }]
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
