class CreateAggregateShipmentStatisticTable < ActiveRecord::Migration
  def change
    create_table :aggregate_shipment_statistics do |t|
      t.date :utc_from, null: false
      t.date :utc_to, null: false
      t.string :resolution, null: false
      t.boolean :aggr_values_ready, null: false, default: false
      t.boolean :needs_refresh, null: false, default: false

      t.references :company, null: false
      t.references :customer
      t.references :carrier
      t.string :carrier_type
      t.references :carrier_product
      t.string :carrier_product_type

      t.integer :total_no_of_packages
      t.integer :total_no_of_shipments
      t.decimal :total_weight, precision: 20, scale: 3
      t.json :total_cost
      t.json :total_revenue
    end

    create_table :aggregate_shipment_statistic_changes do |t|
      t.references :shipment, null: false
      t.datetime :handled_at
    end
  end
end
