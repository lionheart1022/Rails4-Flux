class AddFerryBookingNotificationSettings < ActiveRecord::Migration
  def change
    change_table :email_settings do |t|
      t.boolean :ferry_booking_booked, null: false, default: false
      t.boolean :ferry_booking_failed, null: false, default: false
    end
  end
end
