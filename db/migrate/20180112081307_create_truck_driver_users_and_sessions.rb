class CreateTruckDriverUsersAndSessions < ActiveRecord::Migration
  def change
    change_table :truck_drivers do |t|
      t.references :user
    end

    create_table :token_sessions do |t|
      t.datetime :created_at, null: false
      t.references :company, null: false
      t.references :sessionable, polymorphic: true, null: false
      t.string :type
      t.string :token_value, null: false, index: { unique: true }
      t.json :metadata
      t.datetime :last_used_at
      t.datetime :expired_at
      t.string :expiration_reason
    end
  end
end
