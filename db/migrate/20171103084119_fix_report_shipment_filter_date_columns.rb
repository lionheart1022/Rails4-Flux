class FixReportShipmentFilterDateColumns < ActiveRecord::Migration
  def change
    change_column :report_shipment_filters, :start_date, :date
    change_column :report_shipment_filters, :end_date, :date
  end
end
