class AddressBook < ActiveRecord::Base
  belongs_to :customer
  belongs_to :owner, polymorphic: true
  has_many :contacts, as: :reference, dependent: :destroy

  class << self
    def create_contact(customer_id: nil, contact_data: nil)
      address_book = self.find_or_create_address_book(customer_id: customer_id)
      contact      = address_book.contacts.build

      AddressBook.transaction do
        contact = Contact.create_contact(reference: address_book, contact_data: contact_data)
      end

      return contact
    rescue => e
      raise ModelError.new(e.message, contact)
    end

    def find_or_create_address_book(customer_id: nil)
      self.where(customer_id: customer_id).first_or_create!
    end
  end
end
