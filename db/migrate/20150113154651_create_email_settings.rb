class CreateEmailSettings < ActiveRecord::Migration
  def up
    create_table :email_settings do |t|
      t.integer :user_id
      t.boolean :create, default: true
      t.boolean :book, default: true
      t.boolean :autobook_with_warnings, default: true
      t.boolean :ship, default: true
      t.boolean :delivered, default: true
      t.boolean :problem, default: true
      t.boolean :cancel, default: true
      t.boolean :comment, default: true

      t.timestamps
    end
  end

  def down
    drop_table :email_settings
  end
end
