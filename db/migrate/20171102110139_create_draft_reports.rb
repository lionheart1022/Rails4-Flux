class CreateDraftReports < ActiveRecord::Migration
  def change
    create_table :draft_reports do |t|
      t.datetime :created_at, null: false
      t.references :created_by

      t.references :company, null: false
      t.references :shipment_filter, null: false
      t.references :report_configuration, null: false

      t.references :shipment_collection
      t.datetime :collection_enqueued_at
      t.datetime :collection_started_at
      t.datetime :collection_finished_at

      t.references :generated_report
      t.datetime :report_enqueued_at
      t.datetime :report_started_at
      t.datetime :report_finished_at
    end

    create_table :shipment_collections

    create_table :shipment_collection_items do |t|
      t.references :shipment_collection, null: false
      t.references :shipment, null: false
      t.boolean :selected, null: false, default: true
    end

    create_table :report_shipment_filters do |t|
      t.datetime :created_at, null: false
      t.references :company, null: false
      t.references :customer_recording
      t.references :carrier
      t.datetime :start_date
      t.datetime :end_date
      t.string :report_inclusion
      t.string :pricing_status
      t.string :shipment_state
    end

    create_table :report_configurations do |t|
      t.datetime :created_at, null: false
      t.references :company, null: false
      t.boolean :with_detailed_pricing, null: false
      t.boolean :ferry_booking_data
      t.boolean :truck_driver_data
    end
  end
end
