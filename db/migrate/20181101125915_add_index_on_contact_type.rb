class AddIndexOnContactType < ActiveRecord::Migration
  def change
    add_index :contacts, :type
  end
end
