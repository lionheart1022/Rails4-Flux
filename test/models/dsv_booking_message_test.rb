require "test_helper"

class DSVBookingMessageTest < ActiveSupport::TestCase
  test "generate message with single good" do
    carrier_product = DSVRoadGroupageCarrierProduct.create!(name: "DSV Road Groupage")
    carrier_product.set_credentials(credentials: { customer_number: "2480090" })

    shipment = Shipment.new
    shipment.created_at = Time.zone.now
    shipment.shipping_date = Date.today
    shipment.delivery_instructions = "Here's some instructions!"
    shipment.carrier_product = carrier_product
    shipment.build_sender(company_name: "Cembrit Logistics ❤️ A/S", address_line1: "Sohngårdsholmsvej 2", city: "Aalborg", zip_code: "9100", country_code: "dk")
    shipment.build_recipient(company_name: "STARK Ishøj", address_line1: "Industribuen 15", city: "Ishøj", zip_code: "2635", country_code: "dk")
    shipment.package_dimensions = PackageDimensionsBuilder.build(carrier_product: shipment.carrier_product) do |builder|
      builder.add_package(length: 20, width: 20, height: 20, weight: BigDecimal("8.61"))
    end
    shipment.number_of_packages = 1
    shipment.save!

    DSVPackage.create!(shipment: shipment, unique_identifier: "357033110006019135", package_index: 0, metadata: {})

    message = DSVBookingMessage.new(shipment, "CF1x1x1")

    assert message.as_edifact
  end
end
