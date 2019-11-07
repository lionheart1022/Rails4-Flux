class CreateEconomicSettings < ActiveRecord::Migration
  def change
    create_table :economic_settings do |t|
      t.integer :company_id
      t.string  :agreement_grant_token
      t.string  :layout_number
      t.string  :payment_terms
      t.string  :product_number_ex_vat
      t.string  :product_number_inc_vat
      t.timestamps null: false
    end
    
    add_index :economic_settings, :company_id
  end
end
