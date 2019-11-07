class ContactAddTypeField < ActiveRecord::Migration
  def change
    add_column(:contacts, :type, :string)
  end
end
