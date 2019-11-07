class CustomersAddScopedCompanyId < ActiveRecord::Migration
  def change
    add_column(:customers, :customer_id, :integer)
    add_column(:companies, :current_customer_id, :integer)
  end
end
