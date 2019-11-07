class AddPrivateToAsset < ActiveRecord::Migration
  def change
    add_column :assets, :private, :boolean, default: false
    add_column :assets, :creator_id, :integer
    add_column :assets, :creator_type, :string
  end
end
