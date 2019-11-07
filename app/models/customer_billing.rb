class CustomerBilling
  attr_accessor :configuration
  attr_accessor :report_request

  class << self
    def perform!(*args)
      new(*args).perform!
    end
  end

  def initialize(configuration:, report_request:)
    self.configuration = configuration
    self.report_request = report_request
  end

  def perform!
    result = nil

    configuration.with_lock do
      result = perform_billing_without_lock!
    end

    result
  end

  private

  def perform_billing_without_lock!
    result = nil
    shipment_ids = filtered_shipment_ids

    if shipment_ids.count > 0
      report = configuration.company.create_report!(
        bulk_insert_shipment_ids: shipment_ids,
        with_detailed_pricing: configuration.with_detailed_pricing,
        customer_recording: configuration.customer_recording,
      )

      result = AutomatedReportRequest.build_report_success_result(report)

      # Generate Excel export
      report.generate_excel_report_later!

      # Generate e-conomic invoices (if access is setup)
      if EconomicAccess.active.where(owner: configuration.company).exists?
        report.create_economic_invoices_now!
        EconomicInvoiceRecord.where(parent: report).ready.update_all(job_enqueued_at: Time.now)
        EconomicInvoiceRequestJob.perform_later(report.id, configuration.customer_recording.company_id)
      end
    else
      result = AutomatedReportRequest.build_no_matching_shipments_result
    end

    configuration.schedule_next_billing_from_report_request!(report_request)

    result
  end

  def filtered_shipment_ids
    shipment_filter = build_shipment_filter
    shipment_filter.perform!

    shipment_filter.shipments.pluck(:id)
  end

  def build_shipment_filter
    shipment_filter = ShipmentFilter.new(configuration.customer_recording.shipment_filter_params)
    shipment_filter.report_inclusion = "not_in_report"
    shipment_filter.state = CargofluxConstants::Filter::NOT_CANCELED
    shipment_filter.pricing_status = "priced"

    shipment_filter
  end
end
