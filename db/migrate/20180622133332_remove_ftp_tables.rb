class RemoveFTPTables < ActiveRecord::Migration
  def change
    drop_table :ftp_directories
    drop_table :ftp_files
  end
end
