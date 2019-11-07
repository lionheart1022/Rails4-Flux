class RemoveAddressInfoFromCustomers < ActiveRecord::Migration
  def up
    remove_column(:customers, :address)
    remove_column(:customers, :zip)
    remove_column(:customers, :city)
    remove_column(:customers, :country_code)
    remove_column(:customers, :phone1)
    remove_column(:customers, :phone2)
    remove_column(:customers, :mobile_phone)
    remove_column(:customers, :fax)
  end

  def down
    add_column(:customers, :address, :text)
    add_column(:customers, :zip, :string)
    add_column(:customers, :city, :string)
    add_column(:customers, :country_code, :string)
    add_column(:customers, :phone1, :string)
    add_column(:customers, :phone2, :string)
    add_column(:customers, :mobile_phone, :string)
    add_column(:customers, :fax, :string)
  end
end
