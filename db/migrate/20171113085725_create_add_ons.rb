class CreateAddOns < ActiveRecord::Migration
  def change
    create_table :addons do |t|
      t.datetime :created_at, null: false
      t.datetime :deleted_at
      t.references :company, null: false
      t.string :type, null: false
    end
  end
end
