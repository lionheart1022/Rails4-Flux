class MoveEmploymentDataToUsers < ActiveRecord::Migration
  def up
    add_column :users, :company_id, :integer
    add_column :users, :customer_id, :integer
    add_column :users, :is_admin, :boolean, default: false
    add_column :users, :is_customer, :boolean, default: false
  end
  
  def method_name
    remove_colunm :users, :company_id
    remove_colunm :users, :customer_id
    remove_colunm :users, :is_admin
    remove_colunm :users, :is_customer
  end
end
