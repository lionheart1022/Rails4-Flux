class CreateCarrierProductMarginConfigurations < ActiveRecord::Migration
  def change
    change_table :sales_prices do |t|
      t.boolean :use_margin_config
      t.references :margin_config
    end

    create_table :carrier_product_margin_configurations do |t|
      t.datetime :created_at, null: false
      t.references :created_by
      t.references :owner, polymorphic: true
      t.string :price_document_hash
      t.string :type
      t.json :config_document
    end
  end
end
