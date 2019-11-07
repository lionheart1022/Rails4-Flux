class AddSnapshotToRateSheets < ActiveRecord::Migration
  def change
    add_column :rate_sheets, :rate_snapshot, :json
  end
end
