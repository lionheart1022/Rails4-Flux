class CreateSurcharges < ActiveRecord::Migration
  def change
    create_table :carrier_product_surcharges do |t|
      t.datetime :created_at, null: false
      t.references :created_by
      t.references :carrier_product, null: false
      t.string :type
      t.string :calculation_method
      t.string :charge_value
      t.string :description
      t.boolean :active, null: false
    end
  end
end
