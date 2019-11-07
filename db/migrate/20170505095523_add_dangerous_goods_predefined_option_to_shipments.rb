class AddDangerousGoodsPredefinedOptionToShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :dangerous_goods_predefined_option, :string
  end
end
