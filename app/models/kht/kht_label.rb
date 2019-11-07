require "prawn/measurement_extensions"
require "barby/barcode/code_25_interleaved"
require "barby/outputter/prawn_outputter"

class KHTLabel
  class << self
    def build(*args)
      view = new(*args)
      view.build
      view
    end
  end

  attr_reader :shipment
  attr_reader :package_barcode_number_mapping
  attr_reader :track_trace_number
  attr_reader :waybill_number
  attr_reader :customer_number
  attr_reader :terminal_number

  def initialize(shipment:, package_barcode_number_mapping:, track_trace_number:, waybill_number:, customer_number:, terminal_number:)
    @shipment = shipment
    @package_barcode_number_mapping = package_barcode_number_mapping
    @track_trace_number = track_trace_number
    @waybill_number = waybill_number
    @customer_number = customer_number
    @terminal_number = terminal_number
    @document = Prawn::Document.new(page_size: [107.mm, 190.mm], margin: 0)
  end

  def build
    shipment.package_dimensions.dimensions.each_with_index do |package_dimension, package_index|
      document.start_new_page if package_index > 0

      package_barcode_number = package_barcode_number_mapping.fetch(package_index)
      package = OpenStruct.new(dimension: package_dimension, n: package_index + 1, barcode_number: package_barcode_number)

      PackageLabel.new(
        document: document,
        shipment: shipment,
        package: package,
        track_trace_number: track_trace_number,
        waybill_number: waybill_number,
        customer_number: customer_number,
        terminal_number: terminal_number,
      ).render
    end
  end

  def save_as(filename)
    document.render_file(filename)
  end

  def with_tempfile
    tmp_file = Tempfile.new(["kht-label", ".pdf"], Rails.root.join("tmp"))
    document.render(tmp_file)
    tmp_file.rewind

    yield tmp_file.path
  end

  private

  attr_reader :document

  class PackageLabel
    attr_reader :document
    attr_reader :shipment
    attr_reader :package
    attr_reader :track_trace_number
    attr_reader :waybill_number
    attr_reader :customer_number
    attr_reader :terminal_number

    def initialize(document:, shipment:, package:, track_trace_number:, waybill_number:, customer_number:, terminal_number:)
      @document = document
      @shipment = shipment
      @package = package
      @track_trace_number = track_trace_number
      @waybill_number = waybill_number
      @customer_number = customer_number
      @terminal_number = terminal_number
    end

    def render
      render_pagination
      render_sender
      render_recipient

      move_down 8.mm
      bounding_box([10.mm, cursor], width: (bounds.right - bounds.left - 20.mm)) do
        # Product info
        font_size 16
        font("Helvetica", style: :bold) { text("K. Hansen Transport A/S", align: :center) }
        move_down 4.mm

        stroke_horizontal_rule
        move_down 3.mm

        # Various details
        font_size 10
        text "Shipping date: #{shipment.shipping_date.strftime('%d-%m-%Y')}"
        text "Waybill: #{waybill_number}"
        text "Customer number: #{customer_number}"
        text "Terminal number: #{terminal_number}"
        text "Description: #{shipment.description}"
        text "Dimensions: L=#{package.dimension.length} cm, W=#{package.dimension.width} cm, H=#{package.dimension.height} cm"
        text "Weight: #{package.dimension.weight} kg"
        text "Customer reference: #{shipment.reference}"
        text "Remarks: #{shipment.remarks}"

        move_down 2.mm
        stroke_horizontal_rule
      end

      parcel_barcode = Barby::Code25Interleaved.new(barcode_number_with_odd_length)
      parcel_barcode.include_checksum = true
      Barby::PrawnOutputter.new(parcel_barcode).annotate_pdf(document, x: 10.mm, y: 16.mm, height: 18.mm, xdim: 1)
      font_size 9
      draw_text "T&T number: #{track_trace_number}", at: [10.mm, 11.mm]
    end

    private

    def method_missing(m, *a, &b)
      document.send(m, *a, &b)
    end

    def respond_to_missing?
      document.respond_to?(m)
    end

    def render_pagination
      font_size 8
      text_box "#{package.n} of #{shipment.package_dimensions.dimensions.count}\n##{shipment.unique_shipment_id}", at: [bounds.right - 35.mm, bounds.top - 5.mm], width: 30.mm, align: :right
    end

    def render_sender
      font_size 8
      move_down 5.mm
      bounding_box([5.mm, cursor], height: 25.mm, width: (bounds.right - bounds.left - 10.mm)) do
        text shipment.sender.company_name.presence
        text shipment.sender.address_line1.presence
        text shipment.sender.address_line2.presence
        text shipment.sender.address_line3.presence
        text "#{shipment.sender.zip_code} #{shipment.sender.city}"

        font("Helvetica", style: :italic) do
          text "Attention: #{shipment.sender.attention}"
          text "Phone: #{shipment.sender.phone_number}"
        end
      end
    end

    def render_recipient
      font_size 10
      bounding_box([5.mm, cursor], height: 40.mm, width: (bounds.right - bounds.left - 10.mm)) do
        bounding_box([3.mm, cursor - 3.mm], width: (bounds.right - bounds.left - 6.mm)) do
          font("Helvetica", size: 8, style: :bold) { text("SHIP TO:") }
          move_down 2.mm
          text shipment.recipient.company_name.presence
          text shipment.recipient.address_line1.presence
          text shipment.recipient.address_line2.presence
          text shipment.recipient.address_line3.presence
          font("Helvetica", style: :bold) { text "#{shipment.recipient.zip_code} #{shipment.recipient.city}" }

          font("Helvetica", style: :italic) do
            text "Attention: #{shipment.sender.attention}"
            text "Phone: #{shipment.sender.phone_number}"
          end
        end

        stroke_bounds
      end
    end

    def barcode_number_with_odd_length
      prefix = (package.barcode_number.length % 2) == 0 ? "0" : ""
      "#{prefix}#{package.barcode_number}"
    end
  end
end
