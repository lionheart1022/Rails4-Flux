class AddDgrOptionsOnShipment < ActiveRecord::Migration
  def change
    change_table :shipments do |t|
      t.boolean :dangerous_goods, default: false
      t.string :dangerous_goods_description
      t.string :un_number
      t.string :un_packing_group
      t.string :packing_instruction
      t.string :dangerous_goods_class
    end
  end
end
