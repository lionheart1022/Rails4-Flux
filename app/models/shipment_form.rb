module ShipmentForm
  PERMITTED_CONTACT_FIELDS = %w(
    save_recipient_in_address_book
    save_sender_in_address_book
    company_name
    attention
    address_line1
    address_line2
    address_line3
    zip_code
    city
    country_code
    state_code
    phone_number
    email
    residential
  )

  def self.permitted_contact_fields
    PERMITTED_CONTACT_FIELDS
  end

  PERMITTED_SHIPMENT_FIELDS = %w(
    request_pickup
    shipping_date
    shipping_date(1i)
    shipping_date(2i)
    shipping_date(3i)
    number_of_packages
    number_of_pallets
    dutiable
    customs_currency
    customs_code
    description
    reference
    shipment_type
    parcelshop_id
    return_label
    remarks
    delivery_instructions
    dangerous_goods
    dangerous_goods_predefined_option
    dangerous_goods_description
    un_number
    dangerous_goods_class
    un_packing_group
    packing_instruction
  )

  def self.permitted_shipment_fields
    PERMITTED_SHIPMENT_FIELDS
  end

  PERMITTED_GOODS_LINE_FIELDS = %w(
    amount
    length
    width
    height
    weight
    goods_identifier
    non_stackable
  )

  def self.permitted_goods_line_fields
    PERMITTED_GOODS_LINE_FIELDS
  end
end
