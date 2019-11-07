class AddEstimatedArrivalDateOnShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :estimated_arrival_date, :date
  end
end
