class CreateFerryBookingEdiTables < ActiveRecord::Migration
  def change
    add_column :ferry_bookings, :transfer_in_progress, :boolean, default: false
    add_column :ferry_bookings, :waiting_for_response, :boolean, default: false

    create_table :ferry_booking_requests do |t|
      t.datetime :created_at, null: false
      t.references :ferry_booking, null: false
      t.references :event
      t.references :upload
      t.string :change, null: false
      t.string :ref
      t.integer :failure_count, null: false, default: 0
      t.datetime :completed_at
    end

    create_table :ferry_booking_uploads do |t|
      t.datetime :created_at, null: false
      t.references :company, null: false
      t.text :file_path
      t.text :document, null: false
    end

    create_table :ferry_booking_responses do |t|
      t.datetime :created_at, null: false
      t.references :ferry_booking, null: false
      t.references :event
      t.references :download
      t.json :result
    end

    create_table :ferry_booking_downloads do |t|
      t.datetime :created_at, null: false
      t.references :company, null: false
      t.string :unique_identifier, null: false
      t.text :file_path
      t.text :document, null: false
      t.datetime :parsed_at

      t.index [:company_id, :unique_identifier], unique: true, name: "index_fbd_on_company_id_and_unique_identifier"
    end
  end
end
