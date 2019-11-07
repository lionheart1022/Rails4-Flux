require "prawn/measurement_extensions"
require "barby/barcode/gs1_128"
require "barby/outputter/prawn_outputter"

class DSVLabel
  class << self
    def build(*args)
      view = new(*args)
      view.build
      view
    end
  end

  attr_reader :shipment
  attr_reader :package_sscc_mapping

  def initialize(shipment:, package_sscc_mapping:)
    @shipment = shipment
    @package_sscc_mapping = package_sscc_mapping
    @document = Prawn::Document.new(page_size: [107.mm, 190.mm], margin: 0)
  end

  def build
    shipment.package_dimensions.dimensions.each_with_index do |package_dimension, package_index|
      document.start_new_page if package_index > 0

      package_sscc_number = package_sscc_mapping.fetch(package_index)
      package = OpenStruct.new(dimension: package_dimension, n: package_index + 1, sscc_number: package_sscc_number)

      PackageLabel.new(document: document, shipment: shipment, package: package).render
    end
  end

  def save_as(filename)
    document.render_file(filename)
  end

  def with_tempfile
    tmp_file = Tempfile.new(["dsv-label", ".pdf"], Rails.root.join("tmp"))
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

    def initialize(document:, shipment:, package:)
      @document = document
      @shipment = shipment
      @package = package
    end

    def render
      render_pagination
      render_sender
      render_shipping_date
      render_recipient

      move_down 6.mm
      bounding_box([10.mm, cursor], width: (bounds.right - bounds.left - 20.mm)) do
        # Product info
        font_size 18
        formatted_text([
          { text: "DSV ", color: "102960", styles: [:bold] },
          { text: shipment.carrier_product.dsv_label_text },
        ])

        # AWB
        font_size 26
        move_down 3.mm
        text shipment.awb

        stroke_horizontal_rule
        move_down 3.mm

        # Various details
        font_size 8
        text "Consignment: #{shipment.awb}"
        text "Description: #{shipment.description}"
        text "Dimensions: L=#{package.dimension.length} cm, W=#{package.dimension.width} cm, H=#{package.dimension.height} cm"
        text "Weight: #{package.dimension.weight} kg"
        text "Customer reference: #{shipment.reference}"

        move_down 2.mm
        stroke_horizontal_rule
      end

      # Barcode with SSCC
      sscc_number = package.sscc_number
      sscc_barcode = Barby::Code128.new("#{Barby::Code128::FNC1}00#{sscc_number}")
      Barby::PrawnOutputter.new(sscc_barcode).annotate_pdf(document, x: 10.mm, y: 14.mm, height: 18.mm, xdim: 1.3)
      font_size 9
      draw_text "(00) #{sscc_number}", at: [10.mm, 11.mm]

      # Barcode with destination postal code
      postal_barcode = Barby::Code128.new("#{Barby::Code128::FNC1}420#{shipment.recipient.zip_code}")
      Barby::PrawnOutputter.new(postal_barcode).annotate_pdf(document, x: 10.mm, y: 40.mm, height: 18.mm, xdim: 1.3)
      font_size 9
      draw_text "(420) #{shipment.recipient.zip_code}", at: [10.mm, 37.mm]
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

    def render_shipping_date
      horizontal_line 5.mm, (bounds.right - bounds.left - 5.mm)

      font_size 9
      move_down 3.mm
      bounding_box([5.mm, cursor], width: (bounds.right - bounds.left - 10.mm)) do
        text "Shipping Date: #{shipment.shipping_date.strftime('%Y-%m-%d')}", align: :right
      end
    end

    def render_recipient
      font_size 10
      move_down 3.mm
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

        move_down 5.mm

        stroke_bounds
      end
    end
  end
end
