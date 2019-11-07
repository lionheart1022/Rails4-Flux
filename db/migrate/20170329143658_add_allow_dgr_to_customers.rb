class AddAllowDgrToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :allow_dangerous_goods, :boolean, default: false
  end
end
