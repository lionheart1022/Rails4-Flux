class AddResidentialColumnToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :residential, :boolean
  end
end
