class ScandlinesBookingRequest
  class << self
    def build_from_ferry_booking(ferry_booking, ref:, change:)
      request = new
      request.set_action_code_from_change(change)
      request.recipient = ferry_booking.product.integration.scandlines_id
      request.reference_number = ref
      request.account = ferry_booking.product.integration.account_number
      request.waybill = ferry_booking.shipment.awb
      request.supplier_id = ferry_booking.product.integration.scandlines_id
      request.supplier_name = "Scandlines Deutschland GmbH"
      request.carrier_name = ferry_booking.shipment.company.name
      request.harbour_from = ferry_booking.product.route.port_code_from
      request.harbour_to = ferry_booking.product.route.port_code_to
      request.travel_date = ferry_booking.shipment.shipping_date
      request.travel_time = ferry_booking.product.time_of_departure
      request.accompanied = ferry_booking.with_driver
      request.weight_in_kg = ferry_booking.cargo_weight
      request.empty_cargo = ferry_booking.empty_cargo
      request.truck_type = ferry_booking.truck_type
      request.unit_length_in_cm = ferry_booking.truck_length * 100
      request.regno1 = ferry_booking.truck_registration_number
      request.regno2 = ferry_booking.trailer_registration_number
      request.product = ferry_booking.description_of_goods.presence
      request.addinfo1 = ferry_booking.additional_info_line_1
      request.addinfo2 = ferry_booking.additional_info_line_2

      request
    end
  end

  attr_reader :timestamp

  attr_accessor :recipient
  attr_accessor :action_code
  attr_accessor :reference_number
  attr_accessor :account
  attr_accessor :waybill
  attr_accessor :supplier_id
  attr_accessor :supplier_name
  attr_accessor :carrier_name
  attr_accessor :harbour_from, :harbour_to
  attr_accessor :travel_date, :travel_time
  attr_accessor :accompanied
  attr_accessor :weight_in_kg
  attr_accessor :empty_cargo
  attr_accessor :product
  attr_accessor :truck_type
  attr_accessor :unit_length_in_cm
  attr_accessor :regno1
  attr_accessor :regno2
  attr_accessor :addinfo1
  attr_accessor :addinfo2

  alias_method :accompanied?, :accompanied
  alias_method :empty_cargo?, :empty_cargo

  def initialize(timestamp: Time.now)
    @timestamp = timestamp
  end

  def set_action_code_from_change(change)
    self.action_code =
      case change
      when "create"
        :new
      when "update"
        :modification
      when "cancel"
        :cancellation
      end
  end

  def waybill?
    [:modification, :cancellation].include?(action_code)
  end

  def to_edi_xml
    to_edi_builder.to_xml
  end

  def to_edi_builder
    Nokogiri::XML::Builder.new do |xml|
      xml.datatransfer do
        xml.start do
          xml.recipient recipient
          xml.msgtype "freight booking"
          xml.msgdate formatted_message_date
          xml.msgtime formatted_message_time
        end

        xml.booking do
          xml.general do
            xml.seqnumber 1
            xml.bookingref do
              xml.actioncode formatted_action_code
              xml.ref reference_number
              xml.accountref account
              xml.waybill waybill if waybill?
            end
          end

          xml.contact do
            xml.supplier do
              xml.supplierid supplier_id
              xml.suppliername1 supplier_name
            end
          end

          xml.details do
            xml.shipper do
              xml.carrier carrier_name
            end

            xml.sailing do
              xml.harbourfrom harbour_from
              xml.harbourto harbour_to
              xml.traveldate formatted_travel_date
              xml.traveltime formatted_travel_time
            end

            xml.freight do
              xml.unit do
                xml.accompanied accompanied? ? "Y" : "N"
                xml.trucktype truck_type_to_code
                xml.length unit_length_in_cm
                xml.regno1 regno1
                xml.regno2 regno2
              end

              xml.cargo do
                xml.dangerousgoods "N"
                xml.weight weight_in_kg
                xml.empty empty_cargo? ? "Y" : "N"
                xml.product product || "Groupage"
              end

              xml.addinfo do
                xml.addinfo1 addinfo1 || "/"
                xml.addinfo2 addinfo2
              end
            end
          end
        end

        xml.end do
          xml.nbrbookings 1
        end
      end
    end
  end

  private

  def formatted_action_code
    case action_code
    when :new
      "N"
    when :modification
      "M"
    when :cancellation
      "C"
    end
  end

  # Format YYYYMMDD
  def formatted_travel_date
    if travel_date
      travel_date.strftime("%Y%m%d")
    end
  end

  # Format HHMM
  def formatted_travel_time
    if m = /(?<hours>\d{2}):(?<minutes>\d{2})/.match(travel_time)
      "#{m[:hours]}#{m[:minutes]}"
    end
  end

  # Format YYYYMMDD
  def formatted_message_date
    if timestamp
      timestamp.strftime("%Y%m%d")
    end
  end

  # Format HHMMSS
  def formatted_message_time
    if timestamp
      timestamp.strftime("%H%M%S")
    end
  end

  def truck_type_to_code
    case truck_type
    when "cargo_car"
      "CCAR"
    when "lorry"
      "LORRY"
    when "lorry_and_trailer", "trailer"
      "TRL"
    end
  end
end
