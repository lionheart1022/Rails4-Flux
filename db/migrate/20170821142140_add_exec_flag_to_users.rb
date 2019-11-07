class AddExecFlagToUsers < ActiveRecord::Migration
  def change
    add_column :users, :is_executive, :boolean, default: false
  end
end
