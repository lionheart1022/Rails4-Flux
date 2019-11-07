require "write_xlsx"

class InvoiceValidation < ActiveRecord::Base
  has_many :invoice_validation_row_records
  belongs_to :company, required: true

  module States
    FAILED = 'failed'
    EMPTY_FILE = 'empty_file'
    ERROR_HEADER = 'error_header'
    PREPROCESSING_FILE = 'preprocessing_file'
    PROCESSING_FILE = 'processing_file'
    PREPROCESSED_FILE = 'preprocessed_file'
    PROCESSED_FILE = 'processed_file'
    EXPORTING_EXCEL_ERRORS = 'exporting_excel_errors'
    EXPORTED_EXCEL_ERRORS = 'exported_excel_errors'
  end

  LOADING_STATES = [States::PREPROCESSING_FILE, States::PROCESSING_FILE, States::EXPORTING_EXCEL_ERRORS]

  cattr_accessor :test_file_name

  def invoice_validation_error_rows
    invoice_validation_row_records.where.not(difference_price_amount: 0)
  end

  def attach_file(file_io)
    filename = file_io.original_filename
    s3_key = "invoice_validations/#{SecureRandom.uuid}"
    update!(name: filename, key: s3_key)
    upload_to_s3(path_to_file: file_io, s3_key: s3_key)
  end

  def read_file(&block)
    if Rails.env.test?
      File.open(File.join(Rails.root, InvoiceValidation.test_file_name), "r") do |f|
        yield f.read
      end
    else
      return if key.nil?

      s3 = AWS::S3.new(
        access_key_id: Rails.configuration.s3_storage[:access_key_id],
        secret_access_key: Rails.configuration.s3_storage[:secret_access_key]
      )
      bucket = s3.buckets[Rails.configuration.s3_storage[:bucket]]

      s3_object = bucket.objects[key]
      s3_object.read(&block)
    end
  end

  def shipment_id_column_name
    header_row[shipment_id_column]
  end

  def cost_column_name
    header_row[cost_column]
  end

  def write_error_rows
    processed_shipments_count = 0

    available_shipments = Shipment.find_company_shipments(company_id: company.id)

    invoice_validation_row_records.each do |row|
      shipment_id_or_tracking_number = row.shipment_id
      rounded_cost_price = row.cost.gsub(",",".").to_d.round(2)
      next if shipment_id_or_tracking_number.blank?

      shipment = available_shipments.find_by("unique_shipment_id = ? OR awb = ?", shipment_id_or_tracking_number, shipment_id_or_tracking_number)

      if shipment
        processed_shipments_count += 1
        currency = nil
        advanced_price = shipment.advanced_prices.where(seller: company).first
        rounded_shipment_total_price = 0

        if advanced_price
          currency = advanced_price.cost_price_currency
          rounded_shipment_total_price = advanced_price.total_cost_price_amount.round(2)
        end

        difference = rounded_cost_price.to_d - rounded_shipment_total_price.to_d

        row.update!(unique_shipment_id: shipment_id_or_tracking_number, expected_price_amount: rounded_shipment_total_price, actual_cost_amount: rounded_cost_price, difference_price_amount: difference, expected_price_currency: currency, actual_cost_currency: currency, difference_price_currency: currency)
      end
    end
    update_attributes(processed_shipments_count: processed_shipments_count)
  end

  def failed?
    status == InvoiceValidation::States::FAILED
  end

  def preprocessing_file?
    status == InvoiceValidation::States::PREPROCESSING_FILE
  end

  def processing_file?
    status == InvoiceValidation::States::PROCESSING_FILE
  end

  def exporting_excel_errors?
    status == InvoiceValidation::States::EXPORTING_EXCEL_ERRORS
  end

  def preprocessed_file?
    status == InvoiceValidation::States::PREPROCESSED_FILE
  end

  def processed_file?
    status == InvoiceValidation::States::PROCESSED_FILE
  end

  def exported_excel_errors?
    status == InvoiceValidation::States::EXPORTED_EXCEL_ERRORS
  end

  def empty_file?
    status == InvoiceValidation::States::EMPTY_FILE
  end

  def error_header?
    status == InvoiceValidation::States::ERROR_HEADER
  end

  def invalid_file?
    empty_file? || error_header?
  end

  def in_a_loading_status?
    LOADING_STATES.include? status
  end

  def available_columns_hash
    header_row.compact
  end

  HEADER = {
    :unique_shipment_id => "ID",
    :expected_price_currency => "Expected price currency",
    :expected_price_amount => "Expected price amount",
    :actual_cost_currency => "Actual cost currency",
    :actual_cost_amount => "Actual cost amount",
    :difference_price_currency => "Difference price currency",
    :difference_price_amount => "Difference price amount"
  }

  def generate_excel_errors_report_now!
    Tempfile.open(["cargoflux_invoice_validation_errors_#{id}", ".xlsx"]) do |tmp_file|
      generate_excel_errors!(output_path: tmp_file.path)

      file_name = "cargoflux_invoice_validation_errors_#{id}.xlsx"
      s3_key = "invoice_validations_reports/#{SecureRandom.uuid}"
      s3_object = upload_to_s3(path_to_file: tmp_file.path, s3_key: s3_key)
      download_url = s3_object.url_for(:read, expires: 10.years.to_i, response_content_disposition: "attachment; filename=#{file_name}")

      update!(errors_report_download_url: download_url)
    end
  end

  def generate_excel_errors!(output_path:)
    return if invoice_validation_error_rows.empty?

    workbook = WriteXLSX.new(output_path)
    worksheet = workbook.add_worksheet

    output_generator = OutputGenerator.new(workbook: workbook, worksheet: worksheet)
    output_generator.write_header_row(headers)

    invoice_validation_error_rows.each do |error_row|
      output_generator.new_row do |row|
        row.write_string column_index_for(:unique_shipment_id), error_row.unique_shipment_id
        row.write_string column_index_for(:expected_price_currency), error_row.expected_price_currency
        row.write_number column_index_for(:expected_price_amount), error_row.expected_price_amount
        row.write_string column_index_for(:actual_cost_currency), error_row.actual_cost_currency
        row.write_number column_index_for(:actual_cost_amount), error_row.actual_cost_amount
        row.write_string column_index_for(:difference_price_currency), error_row.difference_price_currency
        row.write_number column_index_for(:difference_price_amount), error_row.difference_price_amount
      end
    end

    output_generator.auto_fit_columns

    workbook.close
  end

  def upload_to_s3(path_to_file:, s3_key:)
    s3 = AWS::S3.new(
      access_key_id: Rails.configuration.s3_storage[:access_key_id],
      secret_access_key: Rails.configuration.s3_storage[:secret_access_key]
    )
    bucket = s3.buckets[Rails.configuration.s3_storage[:bucket]]
    bucket.objects.create(s3_key, file: path_to_file)
  end

  def headers
    HEADER.values
  end

  def column_identifiers
    HEADER.keys
  end

  def column_index_for(column_identifier)
    column_index = column_identifiers.index(column_identifier)

    if column_index.nil?
      raise ArgumentError, "column identifier `#{column_identifer}` is not valid"
    end

    column_index
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
end
