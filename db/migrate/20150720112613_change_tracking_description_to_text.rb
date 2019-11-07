class ChangeTrackingDescriptionToText < ActiveRecord::Migration
  def up
    change_column :trackings, :description, :text
  end

  def down
    change_column :trackings, :description, :string
  end
end
