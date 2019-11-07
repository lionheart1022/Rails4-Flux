class DraftReport < ActiveRecord::Base
  belongs_to :company, required: true
  belongs_to :created_by, required: false, class_name: "User"
  belongs_to :shipment_filter, class_name: "ReportShipmentFilter", required: true, dependent: :destroy
  belongs_to :report_configuration, class_name: "ReportConfiguration", required: true, dependent: :destroy
  belongs_to :shipment_collection, required: false, dependent: :destroy
  belongs_to :generated_report, class_name: "Report", required: false
  has_many :shipment_collection_items, through: :shipment_collection, source: :items

  class << self
    def new_from_params(company, params:)
      draft_report = new(company: company)

      draft_report.build_shipment_filter(
        company: company,
        report_inclusion: "not_in_report",
        shipment_state: CargofluxConstants::Filter::NOT_CANCELED,
        pricing_status: "priced",
      )
      draft_report.build_report_configuration(company: company)

      draft_report.whitelist_and_assign_shipment_filter_params(params[:shipment_filter])
      draft_report.whitelist_and_assign_report_configuration_params(params[:configuration])

      draft_report
    end
  end

  def in_progress?
    collection_in_progress? || report_in_progress?
  end

  def collection_in_progress?
    collection_enqueued_at && !collection_finished_at
  end

  def report_in_progress?
    report_enqueued_at && !report_finished_at
  end

  def all_shipments_selected?
    shipment_collection_items.count == shipment_collection_items.selected.count
  end

  def toggle_shipment!(id:, selected:)
    shipment_collection_items.where(shipment_id: id).update_all(selected: selected)
  end

  def toggle_all_shipment!(selected:)
    shipment_collection_items.update_all(selected: selected)
  end

  def generate_shipment_collection_in_background!
    touch :collection_enqueued_at
    DraftReportJobs::GenerateShipmentCollection.perform_later(id)
  end

  def generate_shipment_collection!
    return if collection_finished_at?

    transaction do
      touch :collection_started_at

      update!(shipment_collection: ShipmentCollection.create!({}))

      shipment_collection_item_rows = shipment_filter.determine_shipment_ids.map do |shipment_id|
        { :shipment_collection_id => shipment_collection.id, :shipment_id => shipment_id }
      end

      bulk_insertion = BulkInsertion.new(shipment_collection_item_rows, column_names: [:shipment_collection_id, :shipment_id], model_class: ShipmentCollectionItem)
      bulk_insertion.perform!

      touch :collection_finished_at
    end
  end

  def generate_report_in_background!
    touch :report_enqueued_at
    DraftReportJobs::GenerateReport.perform_later(id)
  end

  def generate_report!
    return if generated_report && generated_report.persisted?

    transaction do
      touch :report_started_at

      self.generated_report = company.create_report!(
        with_detailed_pricing: report_configuration.with_detailed_pricing,
        ferry_booking_data: report_configuration.ferry_booking_data,
        truck_driver_data: report_configuration.truck_driver_data,
        customer_recording: shipment_filter.customer_recording,
        bulk_insert_shipment_ids: shipment_collection.selected_shipment_ids,
      )
      self.save!

      touch :report_finished_at
    end

    generated_report.generate_excel_report_later!
  end

  def whitelist_and_assign_shipment_filter_params(attrs)
    return if attrs.blank? || shipment_filter.nil?

    shipment_filter.assign_attributes(attrs)
    shipment_filter.customer_recording_id = CustomerRecording.where(company: company, id: shipment_filter.customer_recording_id).limit(1).pluck(:id).first
    shipment_filter.carrier_id = Carrier.where(company: company, id: shipment_filter.carrier_id).limit(1).pluck(:id).first

    shipment_filter
  end

  def whitelist_and_assign_report_configuration_params(attrs)
    return if attrs.blank? || report_configuration.nil?

    report_configuration.assign_attributes(attrs)

    report_configuration
  end

  def report_inclusion_options
    [
      ["Shipments not in a report", "not_in_report"],
    ]
  end

  def pricing_status_options
    [
      ["Priced shipments", "priced"],
      ["Unpriced shipments", "unpriced"],
    ]
  end

  def state_options
    [
      ["Shipments booked and not cancelled", CargofluxConstants::Filter::NOT_CANCELED],
      ["Created", Shipment::States::CREATED],
      ["Booked", Shipment::States::BOOKED],
      ["In transit", Shipment::States::IN_TRANSIT],
      ["Problem", Shipment::States::PROBLEM],
    ]
  end
end
