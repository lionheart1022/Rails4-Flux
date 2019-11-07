class CreatePriceGroups < ActiveRecord::Migration
  def change
    create_table :price_groups do |t|
      t.belongs_to  :company
      t.string      :name
      t.timestamps
    end
  end
end
