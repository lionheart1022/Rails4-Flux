class AddPackageIndexToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :package_index, :integer
  end
end
