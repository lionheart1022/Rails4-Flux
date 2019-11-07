class AddStateToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :state_code, :string
  end
end
