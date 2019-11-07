class CreateCarrierProducts < ActiveRecord::Migration
  def change
    create_table :carrier_products do |t|
      t.belongs_to :company
      t.belongs_to :carrier
      t.belongs_to :carrier_product
      t.string :name
      t.boolean :is_predefined_product
      t.timestamps
    end
  end
end
