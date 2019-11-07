class CreateTokens < ActiveRecord::Migration
  def change
    create_table :tokens do |t|
      t.string  :type
      t.integer :owner_id
      t.string  :owner_type
      t.string  :value

      t.timestamps null: false
    end
  end
end
