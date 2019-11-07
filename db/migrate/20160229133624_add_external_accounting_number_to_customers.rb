class AddExternalAccountingNumberToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :external_accounting_number, :string
  end
end
