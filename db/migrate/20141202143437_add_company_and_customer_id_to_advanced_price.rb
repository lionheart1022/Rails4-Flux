class AddCompanyAndCustomerIdToAdvancedPrice < ActiveRecord::Migration
  def change
    add_column :advanced_prices, :company_id, :integer
    add_column :advanced_prices, :customer_id, :integer
  end
end
