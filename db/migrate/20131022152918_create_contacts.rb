class CreateContacts < ActiveRecord::Migration
  def change
    create_table :contacts do |t|
      t.integer :reference_id
      t.string  :reference_type
      t.string  :company_name
      t.string  :attention
      t.string  :email
      t.string  :phone_number
      t.string  :address_line1
      t.string  :address_line2
      t.string  :zip_code
      t.string  :city
      t.string  :country_code
      t.timestamps
    end
  end
end
