class CustomersAddEndOfDayManifestCounter < ActiveRecord::Migration
  def change
    add_column(:customers, :current_end_of_day_manifest_id, :integer)
  end
end
