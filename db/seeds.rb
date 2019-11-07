# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

############################################################
# Companies
############################################################
if ["staging", "development"].include?(Rails.env)
  cf          = Company.create_company(company_data: {name: "CargoFlux ApS"})
  philipgert  = Company.create_company(company_data: {name: "PG Shipping A/S"})
  interscan   = Company.create_company(company_data: {name: "Interscan"})
  sgs         = Company.create_company(company_data: {name: "SGS"})
end

############################################################
# Company relations
############################################################

if ["staging", "development"].include?(Rails.env)
  EntityRelation.create!(from_reference:cf, to_reference:philipgert, relation_type:EntityRelation::RelationTypes::DIRECT_COMPANY)
  EntityRelation.create!(from_reference:cf, to_reference:interscan, relation_type:EntityRelation::RelationTypes::DIRECT_COMPANY)
  philipgert.add_carrier_product_customer!(sgs)
end

############################################################
# Company users
############################################################
if ["staging", "development"].include?(Rails.env)
  gert_cf = User.create_company_user(
    company_id: cf.id,
    user_data:  {
      email:    "gert+cfadmin@shape.dk",
      password: "testingpass",
      is_admin: true
    }
  )
  gert_cf.confirmed_at = Time.now
  gert_cf.save!

  philip_cf = User.create_company_user(
    company_id: cf.id,
    user_data:  {
      email:    "philip+cfadmin@shape.dk",
      password: "philip123",
      is_admin: true
    }
  )
  philip_cf.confirmed_at = Time.now
  philip_cf.save!

  gert_philipgert = User.create_company_user(
    company_id: philipgert.id,
    user_data:  {
      email:    "gert+philipgert@shape.dk",
      password: "testingpass",
      is_admin: true
    }
  )
  gert_philipgert.confirmed_at = Time.now
  gert_philipgert.save!

  philip_philipgert = User.create_company_user(
    company_id: philipgert.id,
    user_data:  {
      email:    "philip+philipgert@shape.dk",
      password: "philip123",
      is_admin: true
    }
  )
  philip_philipgert.confirmed_at = Time.now
  philip_philipgert.save!

  gert_sgs = User.create_company_user(
    company_id: sgs.id,
    user_data:  {
      email:    "gert+sgsadmin@shape.dk",
      password: "testingpass",
      is_admin: true
    }
  )
  gert_sgs.confirmed_at = Time.now
  gert_sgs.save!

  philip_sgs = User.create_company_user(
    company_id: sgs.id,
    user_data:  {
      email:    "philip+sgsadmin@shape.dk",
      password: "philip123",
      is_admin: true
    }
  )
  philip_sgs.confirmed_at = Time.now
  philip_sgs.save!

  jannick_interscan = User.create_company_user(
    company_id: interscan.id,
    user_data:  {
      email:    "jannicksloth+interscan@gmail.com",
      password: "jannick123",
      is_admin: true
    }
  )
  jannick_interscan.confirmed_at = Time.now
  jannick_interscan.save!
end

############################################################
# Carriers
############################################################
if ["staging", "development", "production"].include?(Rails.env)
  # Global predefined carriers
  predefined_carrier_dhl = Carrier.create_carrier(
    name: "DHL",
    company_id: cf.id
  )

  predefined_carrier_tnt = Carrier.create_carrier(
    name: "TNT",
    company_id: cf.id
  )

  predefined_carrier_ups = Carrier.create_carrier(
    name: "UPS",
    company_id: cf.id
  )

  predefined_carrier_pacsoft = Carrier.create_carrier(
    name: "Pacsoft",
    company_id: cf.id
  )
end

if ["staging", "development"].include?(Rails.env)
  # Company carriers

  # philipgert
  philipgert_dhl = Carrier.create_carrier_from_existing_carrier(
    company_id: philipgert.id,
    existing_carrier_id: predefined_carrier_dhl.id
  )

  philipgert_tnt = Carrier.create_carrier_from_existing_carrier(
    company_id: philipgert.id,
    existing_carrier_id: predefined_carrier_tnt.id
  )

  philipgert_ups = Carrier.create_carrier_from_existing_carrier(
    company_id: philipgert.id,
    existing_carrier_id: predefined_carrier_ups.id
  )

  philipgert_pacsoft = Carrier.create_carrier_from_existing_carrier(
    company_id: philipgert.id,
    existing_carrier_id: predefined_carrier_pacsoft.id
  )

  # interscan
  interscan_dhl = Carrier.create_carrier_from_existing_carrier(
    company_id: interscan.id,
    existing_carrier_id: predefined_carrier_dhl.id
  )

  interscan_tnt = Carrier.create_carrier_from_existing_carrier(
    company_id: interscan.id,
    existing_carrier_id: predefined_carrier_tnt.id
  )
end

############################################################
# Carrier products
############################################################

if ["staging", "development", "production"].include?(Rails.env)
  # Predefined carrier products
  predefined_product_pacsoft_erhvervspakke = PacsoftPostDkErhvervspakkeCarrierProduct.create_carrier_product(
    company_id: cf.id,
    carrier_id: predefined_carrier_pacsoft.id,
    name:       "Post Danmark Erhvervspakke (Pacsoft)",
  )

  predefined_product_dhl_express = DHLExpressCarrierProduct.create_carrier_product(
    company_id: cf.id,
    carrier_id: predefined_carrier_dhl.id,
    name:       "DHL Express",
  )

  predefined_product_dhl_economy = DHLEconomyCarrierProduct.create_carrier_product(
    company_id: cf.id,
    carrier_id: predefined_carrier_dhl.id,
    name:       "DHL Economy",
  )

  predefined_product_tnt_express = TNTExpressCarrierProduct.create_carrier_product(
    company_id: cf.id,
    carrier_id: predefined_carrier_tnt.id,
    name:       "TNT Express",
  )

  predefined_product_tnt_economy = TNTEconomyCarrierProduct.create_carrier_product(
    company_id: cf.id,
    carrier_id: predefined_carrier_tnt.id,
    name:       "TNT Economy",
  )

  predefined_product_tnt_express_import = TNTExpressImportCarrierProduct.create_carrier_product(
    company_id: cf.id,
    carrier_id: predefined_carrier_tnt.id,
    name:       "TNT Express Import",
  )

  predefined_product_tnt_economy_import = TNTEconomyImportCarrierProduct.create_carrier_product(
    company_id: cf.id,
    carrier_id: predefined_carrier_tnt.id,
    name:       "TNT Economy Import",
  )

  predefined_product_tnt_domestic = TNTDomesticCarrierProduct.create_carrier_product(
    company_id: cf.id,
    carrier_id: predefined_carrier_tnt.id,
    name:       "TNT Domestic",
  )

  # UPS
  predefined_product_ups_standard = UPSStandardCarrierProduct.create_carrier_product(
    company_id: cf.id,
    carrier_id: predefined_carrier_ups.id,
    name:       "UPS Standard",
  )

  predefined_product_ups_express = UPSExpressCarrierProduct.create_carrier_product(
    company_id: cf.id,
    carrier_id: predefined_carrier_ups.id,
    name:       "UPS Express",
  )

  predefined_product_ups_expedited = UPSExpeditedCarrierProduct.create_carrier_product(
    company_id: cf.id,
    carrier_id: predefined_carrier_ups.id,
    name:       "UPS Expedited",
  )

  predefined_product_ups_saver = UPSSaverCarrierProduct.create_carrier_product(
    company_id: cf.id,
    carrier_id: predefined_carrier_ups.id,
    name:       "UPS Saver",
  )

  # UPS Import

  predefined_product_ups_standard_import = UPSStandardImportCarrierProduct.create_carrier_product(
    company_id: cf.id,
    carrier_id: predefined_carrier_ups.id,
    name:       "UPS Standard Import",
  )

  predefined_product_ups_expedited_import = UPSExpeditedImportCarrierProduct.create_carrier_product(
    company_id: cf.id,
    carrier_id: predefined_carrier_ups.id,
    name:       "UPS Expedited Import",
  )

  predefined_product_ups_saver_import = UPSSaverImportCarrierProduct.create_carrier_product(
    company_id: cf.id,
    carrier_id: predefined_carrier_ups.id,
    name:       "UPS Saver Import",
  )

  # UPS Single Piece
  predefined_product_ups_standard_single = UPSStandardSingleCarrierProduct.create_carrier_product(
    company_id: cf.id,
    carrier_id: predefined_carrier_ups.id,
    name:       "UPS Standard (Single Package)",
  )

end

if ["staging", "development"].include?(Rails.env)
  # Company carrier products

  # philipgert
  philipgert_dhl_express = CarrierProduct.create_carrier_product_from_existing_product(
    company_id:           philipgert.id,
    carrier_id:           philipgert_dhl.id,
    existing_product_id:  predefined_product_dhl_express.id,
    is_locked:            false,
  )

  CarrierProduct.create_carrier_product_from_existing_product(
    company_id:           philipgert.id,
    carrier_id:           philipgert_dhl.id,
    existing_product_id:  predefined_product_dhl_economy.id,
    is_locked:            false,
  )

  # TNT Export

  CarrierProduct.create_carrier_product_from_existing_product(
    company_id:           philipgert.id,
    carrier_id:           philipgert_tnt.id,
    existing_product_id:  predefined_product_tnt_express.id,
    is_locked:            false,
  )

  CarrierProduct.create_carrier_product_from_existing_product(
    company_id:           philipgert.id,
    carrier_id:           philipgert_tnt.id,
    existing_product_id:  predefined_product_tnt_economy.id,
    is_locked:            false,
  )

  CarrierProduct.create_carrier_product_from_existing_product(
    company_id:           philipgert.id,
    carrier_id:           philipgert_tnt.id,
    existing_product_id:  predefined_product_tnt_domestic.id,
    is_locked:            false,
  )

  # TNT Import

  CarrierProduct.create_carrier_product_from_existing_product(
    company_id:           philipgert.id,
    carrier_id:           philipgert_tnt.id,
    existing_product_id:  predefined_product_tnt_express_import.id,
    is_locked:            false,
  )

  CarrierProduct.create_carrier_product_from_existing_product(
    company_id:           philipgert.id,
    carrier_id:           philipgert_tnt.id,
    existing_product_id:  predefined_product_tnt_economy_import.id,
    is_locked:            false,
  )

  # UPS Export

  CarrierProduct.create_carrier_product_from_existing_product(
    company_id:           philipgert.id,
    carrier_id:           philipgert_ups.id,
    existing_product_id:  predefined_product_ups_standard.id,
    is_locked:            false,
  )

  CarrierProduct.create_carrier_product_from_existing_product(
    company_id:           philipgert.id,
    carrier_id:           philipgert_ups.id,
    existing_product_id:  predefined_product_ups_express.id,
    is_locked:            false,
  )

  CarrierProduct.create_carrier_product_from_existing_product(
    company_id:           philipgert.id,
    carrier_id:           philipgert_ups.id,
    existing_product_id:  predefined_product_ups_expedited.id,
    is_locked:            false,
  )

  CarrierProduct.create_carrier_product_from_existing_product(
    company_id:           philipgert.id,
    carrier_id:           philipgert_ups.id,
    existing_product_id:  predefined_product_ups_saver.id,
    is_locked:            false,
  )

  # UPS Import

  CarrierProduct.create_carrier_product_from_existing_product(
    company_id:           philipgert.id,
    carrier_id:           philipgert_ups.id,
    existing_product_id:  predefined_product_ups_standard_import.id,
    is_locked:            false,
  )

  CarrierProduct.create_carrier_product_from_existing_product(
    company_id:           philipgert.id,
    carrier_id:           philipgert_ups.id,
    existing_product_id:  predefined_product_ups_expedited_import.id,
    is_locked:            false,
  )

  CarrierProduct.create_carrier_product_from_existing_product(
    company_id:           philipgert.id,
    carrier_id:           philipgert_ups.id,
    existing_product_id:  predefined_product_ups_saver_import.id,
    is_locked:            false,
  )

  # UPS Single Piece
  CarrierProduct.create_carrier_product_from_existing_product(
    company_id:           philipgert.id,
    carrier_id:           philipgert_ups.id,
    existing_product_id:  predefined_product_ups_standard_single.id,
    is_locked:            false,
  )

  # Pacsoft
  CarrierProduct.create_carrier_product_from_existing_product(
    company_id:           philipgert.id,
    carrier_id:           philipgert_pacsoft.id,
    existing_product_id:  predefined_product_pacsoft_erhvervspakke.id,
    is_locked:            false,
  )

  # interscan
  CarrierProduct.create_carrier_product_from_existing_product(
    company_id:           interscan.id,
    carrier_id:           interscan_dhl.id,
    existing_product_id:  predefined_product_dhl_express.id,
    is_locked:            false,
  )

  CarrierProduct.create_carrier_product_from_existing_product(
    company_id:           interscan.id,
    carrier_id:           interscan_dhl.id,
    existing_product_id:  predefined_product_dhl_economy.id,
    is_locked:            false,
  )

  CarrierProduct.create_carrier_product_from_existing_product(
    company_id:           interscan.id,
    carrier_id:           interscan_tnt.id,
    existing_product_id:  predefined_product_tnt_express.id,
    is_locked:            false,
  )

  CarrierProduct.create_carrier_product_from_existing_product(
    company_id:           interscan.id,
    carrier_id:           interscan_tnt.id,
    existing_product_id:  predefined_product_tnt_economy.id,
    is_locked:            false,
  )

  CarrierProduct.create_carrier_product_from_existing_product(
    company_id:           interscan.id,
    carrier_id:           interscan_tnt.id,
    existing_product_id:  predefined_product_tnt_domestic.id,
    is_locked:            false,
  )
end

############################################################
# Customers
############################################################
if ["staging", "development"].include?(Rails.env)
  megatech = Customer.create_customer(
    company_id:    philipgert.id,
    customer_data: {
      name:     "Megatech",
      email:    "gert+megatech@shape.dk",
      password: "testingpass"
    },
    contact_data:  {
      company_name:  "Megatech",
      attention:     "Gert Jørgensen",
      address_line1: "Gothersgade 8B",
      address_line2: "3. sal",
      zip_code:      "1123",
      city:          "København K",
      country_code:  "dk",
      phone_number:  "+45 12 34 56 78",
      email:         "gert+megatech@shape.dk"
    },
    id_generator: philipgert
  )

  megatech_user = Customer.find_user(company_id: philipgert.id, customer_id: megatech.id)
  megatech_user.confirmed_at = Time.now
  megatech_user.save!

  megatech = Customer.create_customer(
    company_id:    philipgert.id,
    customer_data: {
      name:     "Mads",
      email:    "mh@shape.dk",
      password: "qswdef321"
    },
    contact_data:  {
      company_name:  "Megatech",
      attention:     "Gert Jørgensen",
      address_line1: "Gothersgade 8B",
      address_line2: "3. sal",
      zip_code:      "1123",
      city:          "København K",
      country_code:  "dk",
      phone_number:  "+45 12 34 56 78",
      email:         "gert+megatech@shape.dk"
    },
    id_generator: philipgert
  )

  megatech_user = Customer.find_user(company_id: philipgert.id, customer_id: megatech.id)
  megatech_user.save!

  shape = Customer.create_customer(
    company_id:    philipgert.id,
    customer_data: {
      name:     "Shape A/S",
      email:    "philip+shape@shape.dk",
      password: "philip123"
    },
    contact_data:  {
      company_name:  "Shape A/S",
      attention:     "Philip Bruce",
      address_line1: "Gothersgade 8B",
      address_line2: "3. sal",
      zip_code:      "1123",
      city:          "København K",
      country_code:  "dk",
      phone_number:  "+45 12 34 56 78",
      email:         "philip+shape@shape.dk"
    },
    id_generator: philipgert
  )

  shape_user = Customer.find_user(company_id: philipgert.id, customer_id: shape.id)
  shape_user.confirmed_at = Time.now
  shape_user.save!

  jannicktransport = Customer.create_customer(
    company_id:    interscan.id,
    customer_data: {
      name:     "Jannick Transport A/S",
      email:    "jannicksloth@gmail.com",
      password: "jannick123"
    },
    contact_data:  {
      company_name:  "Jannick Transport A/S",
      attention:     "Jannick Sloth",
      address_line1: "En gade",
      address_line2: "",
      zip_code:      "1000",
      city:          "København",
      country_code:  "dk",
      phone_number:  "+45 12 34 56 78",
      email:         "jannicksloth@gmail.com"
    },
    id_generator: interscan
  )

  shape_user = Customer.find_user(company_id: interscan.id, customer_id: jannicktransport.id)
  shape_user.confirmed_at = Time.now
  shape_user.save!
end

############################################################
# Customer Carrier Products
############################################################
if ["staging", "development"].include?(Rails.env)
  Company.all.each do |company|
    carrier_products = company.carrier_products

    carrier_product_options = carrier_products.each.map do |carrier_product|
      {
        id: carrier_product.id,
        enable_autobooking: false,
        automatically_autobook: false
      }
    end

    company.customers.each do |customer|
      CustomerCarrierProduct.set_allowed_carrier_products_and_sales_prices(customer_id: customer.id, carrier_product_options: carrier_product_options )
    end
  end
end

############################################################
# Shipments
############################################################
if ["staging", "development"].include?(Rails.env)
  megatech_dhl_express_shipment = Shipment.create_shipment(
    company_id:         philipgert.id,
    customer_id:        megatech.id,
    scoped_customer_id: megatech.customer_id,
    shipment_data:  {
      shipping_date:      Time.zone.now.advance(days: +2),
      carrier_product_id: philipgert_dhl_express.id,
      number_of_packages: 2,
      package_dimensions: PackageDimensions.new(dimensions: [PackageDimension.new(length: 10, width: 20, height: 30, weight: 7), PackageDimension.new(length: 10, width: 20, height: 30, weight: 5)]),
      dutiable:           true,
      customs_amount:     100,
      customs_currency:   "EUR",
      customs_code:       "01110011",
      description:        "IT equipment"
    },
    sender_data: {
      company_name:         megatech.address.company_name,
      attention:            megatech.address.attention,
      address_line1:        megatech.address.address_line1,
      address_line2:        megatech.address.address_line2,
      zip_code:             megatech.address.zip_code,
      city:                 megatech.address.city,
      country_code:         megatech.address.country_code,
      phone_number:         megatech.address.phone_number,
      email:                megatech.address.email,
      save_recipient_in_address_book: megatech.address.save_recipient_in_address_book
    },
    recipient_data: {
      company_name:  "Shape A/S",
      attention:     "Philip Bruce",
      address_line1: "Gothersgade 8B",
      address_line2: "3. sal",
      zip_code:      "1123",
      city:          "København K",
      country_code:  "dk",
      phone_number:  "+45 12 34 56 78",
      email:         "philip@shape.dk",
      save_recipient_in_address_book: "1"
    },
    id_generator: Customer.find_company_customer(company_id: philipgert.id, customer_id: megatech.id)
  )

  shape_dhl_express_shipment = Shipment.create_shipment(
    company_id:         philipgert.id,
    customer_id:        shape.id,
    scoped_customer_id: shape.customer_id,
    shipment_data:  {
      shipping_date:      Time.zone.now.advance(days: +2),
      carrier_product_id: philipgert_dhl_express.id,
      number_of_packages: 2,
      package_dimensions: PackageDimensions.new(dimensions: [PackageDimension.new(length: 10, width: 20, height: 30, weight: 7), PackageDimension.new(length: 10, width: 20, height: 30, weight: 5)]),
      dutiable:           true,
      customs_amount:     100,
      customs_currency:   "EUR",
      customs_code:       "01110011",
      description:        "IT equipment"
    },
    sender_data: {
      company_name:         shape.address.company_name,
      attention:            shape.address.attention,
      address_line1:        shape.address.address_line1,
      address_line2:        shape.address.address_line2,
      zip_code:             shape.address.zip_code,
      city:                 shape.address.city,
      country_code:         shape.address.country_code,
      phone_number:         shape.address.phone_number,
      email:                shape.address.email,
      save_recipient_in_address_book: shape.address.save_recipient_in_address_book
    },
    recipient_data: {
      company_name:  "Baresso Coffee",
      attention:     "Baristaen",
      address_line1: "Kongens Nytorv 24",
      address_line2: nil,
      zip_code:      "1050",
      city:          "København K",
      country_code:  "dk",
      phone_number:  "+45 33 93 93 88",
      email:         nil,
      save_recipient_in_address_book: "1"
    },
    id_generator: Customer.find_company_customer(company_id: philipgert.id, customer_id: shape.id)
  )
end

############################################################
# Pickups
############################################################
if ["staging", "development"].include?(Rails.env)
  megatech_pickup = Pickup.create_pickup(
    company_id:         philipgert.id,
    customer_id:        megatech.id,
    scoped_customer_id: megatech.customer_id,
    pickup_data:  {
      pickup_date:  Time.zone.now.advance(days: +3),
      from_time:    "10:00",
      to_time:      "16:00",
      description:  "Please note that we are not at the office between 12:00 and 12:10"
    },
    contact_data: {
      address_line1: megatech.address.address_line1,
      address_line2: megatech.address.address_line2,
      zip_code:      megatech.address.zip_code,
      city:          megatech.address.city,
      country_code:  megatech.address.country_code
    },
    id_generator: Customer.find_company_customer(company_id: philipgert.id, customer_id: megatech.id)
  )

  shape_pickup = Pickup.create_pickup(
    company_id:         philipgert.id,
    customer_id:        shape.id,
    scoped_customer_id: shape.customer_id,
    pickup_data:  {
      pickup_date:  Time.zone.now.advance(days: +3),
      from_time:    "12:00",
      to_time:      "13:00",
      description:  "Sorry to disturb your lunch!"
    },
    contact_data: {
      address_line1: shape.address.address_line1,
      address_line2: shape.address.address_line2,
      zip_code:      shape.address.zip_code,
      city:          shape.address.city,
      country_code:  shape.address.country_code
    },
    id_generator: Customer.find_company_customer(company_id: philipgert.id, customer_id: shape.id)
  )
end
