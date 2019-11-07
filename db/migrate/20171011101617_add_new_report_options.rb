class AddNewReportOptions < ActiveRecord::Migration
  def change
    change_table :reports do |t|
      t.boolean :ferry_booking_data, default: false
      t.boolean :truck_driver_data, default: false
    end
  end
end
