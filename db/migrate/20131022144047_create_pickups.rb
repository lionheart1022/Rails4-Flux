class CreatePickups < ActiveRecord::Migration
  def change
    create_table :pickups do |t|
      t.integer :user_id
      t.integer :company_id
      t.date    :pickup_date
      t.time    :from_time
      t.time    :to_time
      t.text    :description
      t.string  :state
      t.timestamps
    end
  end
end
