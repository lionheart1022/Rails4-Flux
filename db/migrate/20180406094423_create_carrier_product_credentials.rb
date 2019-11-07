class CreateCarrierProductCredentials < ActiveRecord::Migration
  def change
    create_table :carrier_product_credentials do |t|
      t.timestamps null: false
      t.references :target, polymorphic: true, null: false
      t.references :owner, polymorphic: true
      t.string :type
      t.json :credential_fields
    end
  end
end
