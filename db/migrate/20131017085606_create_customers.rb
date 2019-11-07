class CreateCustomers < ActiveRecord::Migration
  def change
    create_table :customers do |t|
      t.string :name
      t.text   :address
      t.string :zip
      t.string :city
      t.string :country_code
      t.string :phone1
      t.string :phone2
      t.string :mobile_phone
      t.string :fax
      t.timestamps
    end
  end
end
