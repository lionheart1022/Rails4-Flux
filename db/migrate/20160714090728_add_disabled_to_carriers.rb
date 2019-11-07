class AddDisabledToCarriers < ActiveRecord::Migration
  def change
    add_column :carriers, :disabled, :boolean, default: false
  end
end
