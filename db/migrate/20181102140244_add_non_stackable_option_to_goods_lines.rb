class AddNonStackableOptionToGoodsLines < ActiveRecord::Migration
  def change
    add_column :goods_lines, :non_stackable, :boolean, null: false, default: false
  end
end
