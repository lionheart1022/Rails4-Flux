class AddPolymorphicOwnerOnAddressBook < ActiveRecord::Migration
  def change
    add_reference :address_books, :owner, polymorphic: true
  end
end
