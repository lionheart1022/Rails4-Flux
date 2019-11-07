class CreatePermissions < ActiveRecord::Migration
  def change
    create_table :permissions do |t|
      t.integer :company_id
      t.string :type
      t.timestamps null: false
    end
  end
end
