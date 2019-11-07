class AddIndexOnCarrierProductCompanyReference < ActiveRecord::Migration
  def change
    add_index :carrier_products, :company_id
  end
end
