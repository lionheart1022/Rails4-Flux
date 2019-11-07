class BackgroundCustomerImportChanges < ActiveRecord::Migration
  def change
    change_table :customer_imports do |t|
      t.references :created_by
      t.json :file_metadata
      t.datetime :parsing_enqueued_at
      t.datetime :parsing_completed_at
      t.datetime :perform_enqueued_at
      t.datetime :perform_completed_at
      t.boolean :send_invitation_email
    end

    create_table :customer_import_rows do |t|
      t.timestamps null: false
      t.references :customer_import, null: false
      t.json :field_data
    end
  end
end
