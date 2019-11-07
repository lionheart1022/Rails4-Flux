class CreateGoodsLines < ActiveRecord::Migration
  def change
    create_table :shipment_goods do |t|
      t.datetime :created_at, null: false
      t.references :shipment, null: false
      t.string :volume_type, null: false
      t.string :dimension_unit, null: false
      t.string :weight_unit, null: false
    end

    create_table :goods_lines do |t|
      t.references :container, null: false

      t.integer :quantity, null: false
      t.string :goods_identifier, null: false

      t.integer :length
      t.integer :width
      t.integer :height
      t.decimal :weight
      t.decimal :volume_weight
    end

    change_table :shipments do |t|
      t.references :goods
    end
  end
end
