require "write_xlsx"

class ShipmentExcelReport
  FULL_COLUMN_IDENTIFIER_TO_LABEL_MAPPING = {
    :id => "ID",
    :date => "Date",
    :awb => "AWB",
    :description => "Description",
    :customer_name => "Customer",
    :customer_reference => "Customer reference",
    :remarks => "Remarks",
    :delivery_instructions => "Delivery Instructions",
    :product => "Product",
    :packages => "Packages",
    :total_volume_weight => "Total volume weight",
    :total_weight => "Total weight",
    :sender_company_name => "Sender name",
    :sender_address_line_1 => "Sender address line 1",
    :sender_address_line_2 => "Sender address line 2",
    :sender_address_line_3 => "Sender address line 3",
    :sender_zip_code => "Sender zip code",
    :sender_city => "Sender city",
    :sender_country => "Sender country",
    :recipient_company_name => "Recipient company name",
    :recipient_attention => "Recipient attention",
    :recipient_address_line_1 => "Recipient address line 1",
    :recipient_address_line_2 => "Recipient address line 2",
    :recipient_address_line_3 => "Recipient address line 3",
    :recipient_zip_code => "Recipient zip code",
    :recipient_city => "Recipient city",
    :recipient_country => "Recipient country",
    :line_description => "Line description",
    :line_quantity => "Line quantity",
    :cost_price => "Cost price",
    :cost_currency => "Cost currency",
    :sales_price => "Sales price",
    :sales_currency => "Sales currency",
    :total_cost_price => "Total cost price",
    :total_cost_currency => "Total cost currency",
    :total_sales_price => "Total sales price",
    :total_sales_currency => "Total sales currency",
    :internal_notes => "Internal Notes",
    :vat => "VAT",
    :truck_driver => "Truck driver",
    :ferry_route => "Route",
    :ferry_booking_truck_length => "Truck length",
    :ferry_booking_truck_reg => "Truck registration number",
    :ferry_booking_trailer_reg => "Trailer registration number",
    :ferry_booking_additional_info => "Ferry booking additional info",
  }

  DETAILED_PRICING_COLUMN_IDENTIFIERS = [
    :line_description,
    :line_quantity,
    :cost_price,
    :cost_currency,
    :sales_price,
    :sales_currency,
  ]

  TRUCK_DRIVER_COLUMN_IDENTIFIERS = [
    :truck_driver,
  ]

  FERRY_BOOKING_COLUMN_IDENTIFIERS = [
    :ferry_route,
    :ferry_booking_truck_length,
    :ferry_booking_truck_reg,
    :ferry_booking_trailer_reg,
    :ferry_booking_additional_info,
  ]

  attr_accessor :company_id
  attr_accessor :shipments

  def initialize(company_id:, shipments:)
    @column_identifier_to_label_mapping = {}

    self.company_id = company_id
    self.shipments = shipments
  end

  def with_detailed_pricing!
    @with_detailed_pricing = true
  end

  def with_detailed_pricing?
    @with_detailed_pricing
  end

  def with_ferry_booking_data!
    @with_ferry_booking_data = true
  end

  def with_ferry_booking_data?
    @with_ferry_booking_data
  end

  def with_truck_driver_data!
    @with_truck_driver_data = true
  end

  def with_truck_driver_data?
    @with_truck_driver_data
  end

  def generate!(output_path:)
    determine_column_mapping!

    workbook = WriteXLSX.new(output_path)
    worksheet = workbook.add_worksheet

    output_generator = OutputGenerator.new(workbook: workbook, worksheet: worksheet)
    output_generator.write_header_row(headers)

    shipments.includes(:carrier_product, :sender, :recipient, :advanced_prices, :notes).find_each(batch_size: 150).each do |shipment|
      shipment_entry = ShipmentEntry.new(shipment, company_id: company_id)

      # Write initial row
      output_generator.new_row do |row|
        row.write_string column_index_for(:id), transform_to_simple_char_set(shipment_entry.unique_shipment_id)
        row.write_date_time column_index_for(:date), shipment_entry.shipping_date.to_s
        row.write_string column_index_for(:awb), transform_to_simple_char_set(shipment_entry.awb)
        row.write_string column_index_for(:description), transform_to_simple_char_set(shipment_entry.description)
        row.write_string column_index_for(:customer_name), transform_to_simple_char_set(shipment_entry.customer_name)
        row.write_string column_index_for(:customer_reference), transform_to_simple_char_set(shipment_entry.reference)
        row.write_string column_index_for(:remarks), transform_to_simple_char_set(shipment_entry.remarks)
        row.write_string column_index_for(:delivery_instructions), shipment_entry.delivery_instructions
        row.write_string column_index_for(:product), transform_to_simple_char_set(shipment_entry.carrier_product.name)
        row.write_number column_index_for(:packages), shipment_entry.number_of_packages
        row.write_number column_index_for(:total_volume_weight), shipment_entry.package_dimensions.total_volume_weight
        row.write_number column_index_for(:total_weight), shipment_entry.package_dimensions.total_weight
        row.write_string column_index_for(:sender_company_name), transform_to_simple_char_set(shipment_entry.sender.company_name)
        row.write_string column_index_for(:sender_address_line_1), transform_to_simple_char_set(shipment_entry.sender.address_line1)
        row.write_string column_index_for(:sender_address_line_2), transform_to_simple_char_set(shipment_entry.sender.address_line2)
        row.write_string column_index_for(:sender_address_line_3), transform_to_simple_char_set(shipment_entry.sender.address_line3)
        row.write_string column_index_for(:sender_zip_code), transform_to_simple_char_set(shipment_entry.sender.zip_code)
        row.write_string column_index_for(:sender_city), transform_to_simple_char_set(shipment_entry.sender.city)
        row.write_string column_index_for(:sender_country), transform_to_simple_char_set(shipment_entry.sender.country_name)
        row.write_string column_index_for(:recipient_company_name), transform_to_simple_char_set(shipment_entry.recipient.company_name)
        row.write_string column_index_for(:recipient_attention), transform_to_simple_char_set(shipment_entry.recipient.attention)
        row.write_string column_index_for(:recipient_address_line_1), transform_to_simple_char_set(shipment_entry.recipient.address_line1)
        row.write_string column_index_for(:recipient_address_line_2), transform_to_simple_char_set(shipment_entry.recipient.address_line2)
        row.write_string column_index_for(:recipient_address_line_3), transform_to_simple_char_set(shipment_entry.recipient.address_line3)
        row.write_string column_index_for(:recipient_zip_code), transform_to_simple_char_set(shipment_entry.recipient.zip_code)
        row.write_string column_index_for(:recipient_city), transform_to_simple_char_set(shipment_entry.recipient.city)
        row.write_string column_index_for(:recipient_country), transform_to_simple_char_set(shipment_entry.recipient.country_name)
        row.write_string column_index_for(:internal_notes), transform_to_simple_char_set(shipment_entry.internal_notes)
        row.write_string column_index_for(:vat), transform_to_simple_char_set(shipment_entry.formatted_vat)

        if with_truck_driver_data? && shipment_entry.truck_driver
          row.write_string column_index_for(:truck_driver), transform_to_simple_char_set(shipment_entry.truck_driver.name)
        end

        if with_ferry_booking_data? && shipment_entry.ferry_booking_shipment?
          row.write_string column_index_for(:ferry_route), shipment_entry.ferry_booking.route.name
          row.write_number column_index_for(:ferry_booking_truck_length), shipment_entry.ferry_booking.truck_length
          row.write_string column_index_for(:ferry_booking_truck_reg), transform_to_simple_char_set(shipment_entry.ferry_booking.truck_registration_number)
          row.write_string column_index_for(:ferry_booking_trailer_reg), transform_to_simple_char_set(shipment_entry.ferry_booking.trailer_registration_number)
          row.write_string column_index_for(:ferry_booking_additional_info), shipment_entry.ferry_booking.additional_info_from_response
        end
      end

      write_totals_proc = Proc.new do |row|
        row.write_number column_index_for(:total_cost_price), shipment_entry.cost_price_amount.round(2)
        row.write_string column_index_for(:total_cost_currency), shipment_entry.cost_price_currency
        row.write_number column_index_for(:total_sales_price), shipment_entry.sales_price_amount.round(2)
        row.write_string column_index_for(:total_sales_currency), shipment_entry.sales_price_currency
      end

      if with_detailed_pricing?
        # Write a row per line item
        shipment_entry.line_items.each do |line_item|
          output_generator.new_row do |row|
            row.write_number column_index_for(:line_description), line_item.description
            row.write_number column_index_for(:line_quantity), line_item.times
            row.write_number column_index_for(:cost_price), line_item.cost_price_amount.round(2) if line_item.cost_price_amount
            row.write_string column_index_for(:cost_currency), shipment_entry.cost_price_currency
            row.write_number column_index_for(:sales_price), line_item.sales_price_amount.round(2) if line_item.sales_price_amount
            row.write_string column_index_for(:sales_currency), shipment_entry.sales_price_currency
          end
        end

        # Write a final row cost+sales line
        output_generator.new_row(&write_totals_proc)
      else
        # Write on the initial row
        output_generator.previous_row(&write_totals_proc)
      end
    end

    output_generator.auto_fit_columns

    workbook.close
  end

  private

  def column_index_for(column_identifer)
    column_index = column_identifiers.index(column_identifer)

    if column_index.nil?
      raise ArgumentError, "column identifier `#{column_identifer}` is not valid"
    end

    column_index
  end

  def column_identifiers
    @column_identifier_to_label_mapping.keys
  end

  def headers
    @column_identifier_to_label_mapping.values
  end

  def determine_column_mapping!
    @column_identifier_to_label_mapping = FULL_COLUMN_IDENTIFIER_TO_LABEL_MAPPING.dup

    unless with_detailed_pricing?
      @column_identifier_to_label_mapping.reject! { |column_identifier, _| DETAILED_PRICING_COLUMN_IDENTIFIERS.include?(column_identifier) }
    end

    unless with_truck_driver_data?
      @column_identifier_to_label_mapping.reject! { |column_identifier, _| TRUCK_DRIVER_COLUMN_IDENTIFIERS.include?(column_identifier) }
    end

    unless with_ferry_booking_data?
      @column_identifier_to_label_mapping.reject! { |column_identifier, _| FERRY_BOOKING_COLUMN_IDENTIFIERS.include?(column_identifier) }
    end
  end

  def transform_to_simple_char_set(string)
    string ? I18n.transliterate(string) : string
  end

  class ShipmentEntry < SimpleDelegator
    def initialize(shipment, company_id:)
      self.advanced_price = shipment.advanced_prices.select { |advanced_price| advanced_price.seller_id == company_id }.first
      self.shipment_note = shipment.notes.select { |note| note.creator_id == company_id && note.creator_type == "Company" }.first
      self.customer_name = shipment.customer_name_for_company(company_id: company_id) || ""
      super(shipment)
    end

    def customer_name
      @customer_name
    end

    def cost_price_amount
      advanced_price.try(:total_cost_price_amount) || 0
    end

    def cost_price_currency
      advanced_price.try(:cost_price_currency) || ""
    end

    def sales_price_amount
      advanced_price.try(:total_sales_price_amount) || 0
    end

    def sales_price_currency
      advanced_price.try(:sales_price_currency) || ""
    end

    def internal_notes
      shipment_note.try(:text) || ""
    end

    def delivery_instructions
      __getobj__.delivery_instructions.present? ? "Deposit" : ""
    end

    def formatted_vat
      if ShipmentVatPolicy.new(__getobj__).include_vat?
        "Included"
      else
        "Excluded"
      end
    end

    def line_items
      advanced_price ? advanced_price.advanced_price_line_items : AdvancedPriceLineItem.none
    end

    def ferry_booking
      if defined?(@ferry_booking)
        @ferry_booking
      else
        @ferry_booking = FerryBooking.find_by!(shipment: __getobj__)
      end
    end

    private

    attr_accessor :advanced_price
    attr_accessor :shipment_note
    attr_accessor :customer_name
  end

  class OutputGenerator
    attr_reader :workbook, :worksheet

    def initialize(workbook:, worksheet:)
      self.workbook = workbook
      self.worksheet = worksheet

      self.header_format = workbook.add_format(bold: 1)
      self.date_format = workbook.add_format(num_format: "yyyy-mm-dd")

      self.current_row_index = 0
      self.column_widths = {}
    end

    def write_header_row(header_labels)
      header_labels.each_with_index do |header_label, column_index|
        worksheet.write_string(0, column_index, header_label)
        adjust_column_width(column_index, header_label)
      end

      worksheet.set_row(0, nil, header_format)

      self.current_row_index = 1
    end

    def new_row
      yield OutputGeneratorRow.new(generator: self, index: current_row_index)

      self.current_row_index += 1
    end

    def previous_row
      yield OutputGeneratorRow.new(generator: self, index: current_row_index - 1)
    end

    def write_number(row_index, column_index, value)
      if !value.nil?
        worksheet.write_number(row_index, column_index, value)
        adjust_column_width(column_index, value)
      end
    end

    def write_string(row_index, column_index, value)
      if !value.nil?
        worksheet.write_string(row_index, column_index, value)
        adjust_column_width(column_index, value)
      end
    end

    def write_date_time(row_index, column_index, value)
      if !value.nil?
        worksheet.write_date_time(row_index, column_index, value, date_format)
        adjust_column_width(column_index, value)
      end
    end

    def auto_fit_columns
      column_widths.each do |column_index, column_width|
        worksheet.set_column(column_index, column_index, column_width)
      end
    end

    protected

    attr_accessor :current_row_index
    attr_accessor :column_widths

    def adjust_column_width(column_index, value)
      # This cell width is not exact just approximate
      cell_width = value.to_s.length

      if column_widths[column_index].nil? || (column_widths[column_index] && column_widths[column_index] < cell_width)
        self.column_widths[column_index] = cell_width
      end
    end

    private

    attr_writer :workbook, :worksheet
    attr_accessor :header_format
    attr_accessor :date_format
  end

  class OutputGeneratorRow
    def initialize(generator:, index:)
      self.generator = generator
      self.index = index
    end

    def write_number(column_index, value)
      generator.write_number(index, column_index, value)
    end

    def write_string(column_index, value)
      generator.write_string(index, column_index, value)
    end

    def write_date_time(column_index, value)
      generator.write_date_time(index, column_index, value)
    end

    private

    attr_accessor :generator
    attr_accessor :index
  end

  private_constant :ShipmentEntry, :OutputGenerator, :OutputGeneratorRow
end
