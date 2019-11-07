class RemoveDeprecatedCustomerIdFromBillingConfig < ActiveRecord::Migration
  def change
    remove_column :customer_billing_configurations, :customer_id
  end
end
