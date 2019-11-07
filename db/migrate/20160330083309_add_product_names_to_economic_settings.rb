class AddProductNamesToEconomicSettings < ActiveRecord::Migration
  def change
    add_column :economic_settings, :product_name_inc_vat, :string
    add_column :economic_settings, :product_name_ex_vat, :string
  end
end
