class CreateInvoiceValidationTables < ActiveRecord::Migration
  def change
    create_table :invoice_validations do |t|
      t.string :name
      t.string :key
      t.string :shipment_id_column
      t.string :cost_column
      t.string :status
      t.json :header_row
      t.integer :processed_shipments_count
      t.references :company, index: true, foreign_key: true, null: false
      t.string :errors_report_download_url

      t.timestamps null: false
    end

    create_table :invoice_validation_row_records do |t|
      t.references :invoice_validation, index: true, foreign_key: true, null: false
      t.string :unique_shipment_id
      t.string :expected_price_currency
      t.decimal :expected_price_amount, precision: 20, scale: 12
      t.string :actual_cost_currency
      t.decimal :actual_cost_amount, precision: 20, scale: 12
      t.string :difference_price_currency
      t.decimal :difference_price_amount, precision: 20, scale: 12
      t.json :field_data
      t.index [:unique_shipment_id, :invoice_validation_id], unique: true, name: "index_error_rows_on_unique_shipment_and_invoice_validation_ids" 

      t.timestamps null: false
    end
  end
end
