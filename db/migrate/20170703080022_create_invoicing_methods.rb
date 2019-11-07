class CreateInvoicingMethods < ActiveRecord::Migration
  def change
    create_table :invoicing_methods do |t|
      t.references :company, null: false
      t.string :type

      t.index :company_id, unique: true
    end
  end
end
