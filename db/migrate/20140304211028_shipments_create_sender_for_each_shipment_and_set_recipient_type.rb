class ShipmentsCreateSenderForEachShipmentAndSetRecipientType < ActiveRecord::Migration
  def up
    Contact.where(reference_type:Shipment.to_s).each do |contact|
      contact.type = Recipient.to_s
      contact.save!
    end

    Shipment.all.each do |shipment|
      customer_address = shipment.customer.address
      sender = Sender.new(
        reference:     customer_address.reference,
        company_name:  customer_address.company_name,
        attention:     customer_address.attention,
        email:         customer_address.email,
        phone_number:  customer_address.phone_number,
        address_line1: customer_address.address_line1,
        address_line2: customer_address.address_line2,
        zip_code:      customer_address.zip_code,
        city:          customer_address.city,
        country_code:  customer_address.country_code
      )
      sender.type = Sender.to_s
      shipment.sender = sender
      shipment.save!
    end
  end
end
