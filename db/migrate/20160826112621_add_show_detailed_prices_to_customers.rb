class AddShowDetailedPricesToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :show_detailed_prices, :boolean, default: false
  end
end
