class CreateCustomerImports < ActiveRecord::Migration
  def change
    create_table :customer_imports do |t|
      t.references :company
      t.string :status
      t.timestamps null: false
    end
  end
end
