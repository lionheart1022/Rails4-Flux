class AddCvrAndNoteToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :cvr_number, :string
    add_column :contacts, :note, :text
  end
end
