class CreateCarriers < ActiveRecord::Migration
  def change
    create_table :carriers do |t|
      t.belongs_to :company
      t.belongs_to :carrier
      t.string :name
      t.boolean :is_predefined_carrier
      t.timestamps
    end
  end
end
