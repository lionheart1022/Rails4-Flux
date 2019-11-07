class AddAddressLine3ToContact < ActiveRecord::Migration
  def change
    add_column :contacts, :address_line3, :string
  end
end
