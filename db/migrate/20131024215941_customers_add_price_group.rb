class CustomersAddPriceGroup < ActiveRecord::Migration
  def change
    add_column(:customers, :price_group_id, :integer)
  end
end
