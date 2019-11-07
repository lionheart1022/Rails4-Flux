class DropAutobookColumnFromEmailSettings < ActiveRecord::Migration
  def up
    execute "ALTER TABLE email_settings DROP COLUMN IF EXISTS autobook"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
