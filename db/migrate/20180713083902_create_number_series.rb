class CreateNumberSeries < ActiveRecord::Migration
  def change
    create_table :number_series do |t|
      t.datetime :created_at, null: false
      t.datetime :disabled_at
      t.string :type
      t.integer :next_value, null: false, default: 0
      t.integer :max_value, null: false
      t.json :metadata
    end
  end
end
