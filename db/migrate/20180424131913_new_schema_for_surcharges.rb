class NewSchemaForSurcharges < ActiveRecord::Migration
  def change
    create_table :surcharges do |t|
      t.string :type
      t.json :charge_data
      t.string :description
    end

    create_table :surcharges_on_carriers do |t|
      t.datetime :created_at, null: false
      t.datetime :disabled_at
      t.references :surcharge, null: false
      t.references :carrier, null: false
    end

    create_table :surcharges_on_products do |t|
      t.datetime :created_at, null: false
      t.datetime :disabled_at
      t.references :parent, null: false
      t.references :surcharge, null: false
      t.references :carrier_product, null: false
    end
  end
end
