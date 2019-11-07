class Report < ActiveRecord::Base
  belongs_to :company, required: true
  belongs_to :customer_recording, required: false

  has_many :shipment_associations, class_name: "ShipmentJoinModel"
  has_many :shipments, through: :shipment_associations

  has_one :automated_report_request

  has_many :economic_invoice_exports, class_name: "EconomicInvoiceExportRecord", as: :parent
  has_many :economic_invoices, class_name: "EconomicInvoiceRecord", as: :parent

  attr_accessor :bulk_insert_shipment_ids

  after_create :insert_shipment_ids_in_bulk

  module States
    IN_PROGRESS = 'in_progress'
    FAILED      = 'failed'
    SUCCESSFUL  = 'successful'
  end

  module EconomicInvoices
    module States
      IN_PROGRESS = 'in_progress'
      FAILED      = 'failed'
      SUCCESSFUL  = 'successful'
    end
  end

  module Queues
    REPORTS = 'reports'
  end

  # PUBLIC API
  class << self

    def update_state(company_id: nil, report_id: nil, state: nil)
      self.where(company_id: company_id, id: report_id).update_all(state: state)
    end

    def update_economic_invoices_state(company_id: nil, report_id: nil, state: nil)
      self.where(company_id: company_id, id: report_id).update_all(economic_invoices_state: state)
    end

    # Finders

    def find_company_reports(company_id: nil)
      self.where(company_id: company_id)
    end

    def find_company_report(company_id: nil, report_id: nil)
      self.where(company_id: company_id).where(id: report_id).first
    end

  end

  # INSTANCE API
  def number_of_shipments
    self.shipments.count
  end

  def number_of_packages
    self.shipments.to_a.sum(:number_of_packages)
  end

  def total_weight
    shipments.to_a.sum(&:total_weight)
  end

  def successful?
    self.state == States::SUCCESSFUL
  end

  def failed?
    self.state == States::FAILED
  end

  def in_progress?
    self.state == States::IN_PROGRESS
  end

  def ordered_shipments
    shipments.order(shipping_date: :asc, id: :asc)
  end

  def has_economic_invoice_export?
    economic_invoice_exports.exists?
  end

  def in_progress_economic_invoice_export?
    economic_invoice_exports.in_progress.exists?
  end

  def no_in_progress_economic_invoice_export?
    !in_progress_economic_invoice_export?
  end

  def create_economic_invoices_later!
    new_export = nil

    transaction do
      if economic_invoice_exports.empty?
        new_export = economic_invoice_exports.create!
      end
    end

    EconomicInvoiceExportJob.perform_later(new_export.id) if new_export

    new_export
  end

  def create_economic_invoices_now!
    new_export = nil

    transaction do
      if economic_invoice_exports.empty?
        new_export = economic_invoice_exports.create!
      end
    end

    new_export.generate_and_create_invoices! if new_export

    new_export
  end

  def all_economic_invoices_succeeded?
    economic_invoices.count > 0 && economic_invoices.count == economic_invoices.succeeded.count
  end

  def some_economic_invoice_are_in_progress?
    economic_invoices.enqueued.exists?
  end

  def any_economic_invoices?
    economic_invoices.count > 0
  end

  def generate_excel_report_later!
    if persisted?
      GenerateExcelReportJob.perform_later(id)
    else
      raise "The `Report`-record should be persisted before you can generate Excel file"
    end
  end

  def generate_excel_report_now!
    excel_report = ShipmentExcelReport.new(company_id: company_id, shipments: ordered_shipments)
    excel_report.with_detailed_pricing! if with_detailed_pricing?
    excel_report.with_truck_driver_data! if truck_driver_data?
    excel_report.with_ferry_booking_data! if ferry_booking_data?

    if Rails.env.test?
      file_name = "test_report_#{report_id}-#{SecureRandom.uuid}.xlsx"
      output_path = Rails.root.join("tmp", file_name)

      excel_report.generate!(output_path: output_path)

      update!(download_url: "file://#{output_path.to_s}")
    else
      Tempfile.open(["cargoflux_report_#{report_id}", ".xlsx"]) do |tmp_file|
        excel_report.generate!(output_path: tmp_file.path)

        file_name = "cargoflux_report_#{report_id}.xlsx"
        s3_key = "reports/#{SecureRandom.uuid}"
        s3_object = upload_to_s3(path_to_file: tmp_file.path, s3_key: s3_key)
        download_url = s3_object.url_for(:read, expires: 10.years.to_i, response_content_disposition: "attachment; filename=#{file_name}")

        update!(download_url: download_url)
      end
    end
  end

  private

  def insert_shipment_ids_in_bulk
    rows =
      Array(bulk_insert_shipment_ids)
      .reject(&:blank?)
      .map { |shipment_id| { report_id: id, shipment_id: shipment_id } }

    bulk_insertion = BulkInsertion.new(rows, column_names: [:report_id, :shipment_id], model_class: ShipmentJoinModel)
    bulk_insertion.perform!
  end

  def upload_to_s3(path_to_file:, s3_key:)
    s3 = AWS::S3.new(
      access_key_id: Rails.configuration.s3_storage[:access_key_id],
      secret_access_key: Rails.configuration.s3_storage[:secret_access_key]
    )
    bucket = s3.buckets[Rails.configuration.s3_storage[:bucket]]
    bucket.objects.create(s3_key, file: path_to_file)
  end

  class ShipmentJoinModel < ActiveRecord::Base
    self.table_name = "reports_shipments"

    belongs_to :report, required: true
    belongs_to :shipment, required: true
  end
end
