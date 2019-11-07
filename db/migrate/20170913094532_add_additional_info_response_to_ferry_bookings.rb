class AddAdditionalInfoResponseToFerryBookings < ActiveRecord::Migration
  def change
    add_column :ferry_bookings, :additional_info_from_response, :string
  end
end
