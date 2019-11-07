class CreateSurchargesWithExpiration < ActiveRecord::Migration
  def change
    change_column_null :surcharges_on_carriers, :surcharge_id, true
    change_column_null :surcharges_on_products, :surcharge_id, true

    create_table :surcharges_with_expiration do |t|
      t.datetime :created_at, null: false
      t.references :owner, polymorphic: true, null: false
      t.references :surcharge
      t.datetime :valid_from
      t.datetime :expires_on
    end
  end
end
