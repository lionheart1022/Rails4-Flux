class CreateReports < ActiveRecord::Migration
  def change
    create_table :reports do |t|
      t.belongs_to  :company
      t.integer     :report_id
      t.timestamps
    end

    create_table :reports_shipments do |t|
      t.belongs_to :report
      t.belongs_to :shipment
    end

    add_column(:companies, :current_report_id, :integer)
  end
end
