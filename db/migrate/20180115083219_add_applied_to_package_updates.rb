class AddAppliedToPackageUpdates < ActiveRecord::Migration
  def change
    add_column :package_updates, :applied_at, :datetime
  end
end
