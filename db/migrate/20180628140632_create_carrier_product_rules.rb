class CreateCarrierProductRules < ActiveRecord::Migration
  def change
    create_table :carrier_product_rules do |t|
      t.timestamps null: false
      t.references :carrier_product, null: false, index: true
      t.string :recipient_type
      t.json :recipient_location
    end

    create_table :rule_intervals do |t|
      t.references :rule, null: false, index: true
      t.boolean :enabled, null: false, default: false
      t.string :type
      t.string :interval_type
      t.string :from
      t.boolean :from_inclusive
      t.string :to
      t.boolean :to_inclusive
    end
  end
end
