class CreateAddressBooks < ActiveRecord::Migration
  def change
    create_table :address_books do |t|
      t.belongs_to :customer
      t.timestamps
    end
  end
end
