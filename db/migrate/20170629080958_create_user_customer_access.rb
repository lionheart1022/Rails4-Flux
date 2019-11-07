class CreateUserCustomerAccess < ActiveRecord::Migration
  def change
    create_table :user_customer_accesses do |t|
      t.datetime :created_at, null: false
      t.datetime :revoked_at
      t.references :user, null: false
      t.references :company, null: false
      t.references :customer, null: false
    end

    add_column :users, :customer_access_migrated, :boolean, null: false, default: false
  end
end
