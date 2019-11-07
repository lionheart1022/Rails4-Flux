class ShipmentMailerPreview < ActionMailer::Preview
  def shipment_created_email
    customer = Customer.new(name: "Customer")
    company = Company.new(name: "Company", info_email: "company@example.com")
    carrier_product = CarrierProduct.new(name: "Some product")

    shipment = Shipment.new(
      id: 1,
      company: company,
      customer: customer,
      unique_shipment_id: "1-1-1",
      shipping_date: Date.today,
      number_of_packages: 1,
      carrier_product: carrier_product,
      reference: "REFERENCE",
      remarks: "REMARKS",
    )

    shipment.build_sender(
      company_name: "Aamazon",
      attention: "",
      address_line1: "Some Place",
      address_line2: nil,
      address_line3: nil,
      zip_code: "",
      country_name: "USA",
      email: "",
      phone_number: "+01 123456789",
    )
    shipment.build_recipient(
      company_name: "Shape",
      attention: "Beykin",
      address_line1: "Njalsgade 17A",
      address_line2: nil,
      address_line3: nil,
      zip_code: "2300",
      country_name: "København S",
      email: "bacon@shape.dk",
      phone_number: nil,
    )
    shipment.package_dimensions = PackageDimensions.new(
      dimensions: [
        PackageDimension.new(length: 10.0, width: 20.0, height: 30.0, weight: 2.0, volume_weight: 1.5),
        PackageDimension.new(length: 20.0, width: 100.0, height: 30.0, weight: 2.0, volume_weight: 1.5),
        PackageDimension.new(length: 20.0, width: 100.0, height: 30.0, weight: 2.0, volume_weight: 1.5),
        PackageDimension.new(length: 20.0, width: 100.0, height: 30.0, weight: 2.0, volume_weight: 1.5),
        PackageDimension.new(length: 20.0, width: 100.0, height: 30.0, weight: 2.0, volume_weight: 1.5),
      ],
      volume_type: "volume_weight",
    )

    user = User.new
    user.build_email_settings(create: true)

    ShipmentMailer.shipment_created_email(user: user, customer: customer, company: company, shipment: shipment)
  end
end
