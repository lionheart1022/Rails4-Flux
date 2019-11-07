require "test_helper"

class KHTBookingTest < ActiveSupport::TestCase
  test "generates message" do
    company = FactoryBot.create(:company)
    customer = FactoryBot.create(:customer)

    carrier_product = FactoryBot.create(:carrier_product, company: company, state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
    carrier_product.set_credentials(credentials: {
      sender_id: "11112222-3333-4444-5555-666677778888",
      customer_number: "43230123",
      ftp_user: ENV.fetch("KHT_FTP_USER"),
      ftp_host: ENV.fetch("KHT_FTP_HOST"),
      ftp_password: ENV.fetch("KHT_FTP_PASSWORD"),
    })

    CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product, is_disabled: false, test: true)

    KHTNumberSeries.create!(max_value: 9114999, next_value: 9095000)

    shipment = Shipment.create!(
      company: company,
      customer: customer,
      carrier_product: carrier_product,
      shipping_date: Date.today,
      unique_shipment_id: "1-1-1",
      reference: "6327",
      remarks: "SKAL LEVERES INDEN KL. 14.00",
      number_of_packages: 1,
      package_dimensions: PackageDimensionsBuilder.build(carrier_product: carrier_product) do |builder|
        builder.add_package(length: 120, width: 80, height: 150, weight: BigDecimal("600"))
      end
    )
    shipment.create_sender!(company_name: "VVS TRADING A/S", address_line2: "ELLEGÅRDVEJ 30", city: "SØNDERBORG", zip_code: "6400", country_code: "DK")
    shipment.create_recipient!(company_name: "JEM & FIX SVENDBORG", address_line2: "VESTERGADE 100", city: "SVENDBORG", zip_code: "5700", country_code: "DK")

    booking_result = KHTBooking.perform!(shipment)
  end
end if ENV.keys.grep(/^KHT_FTP_/).any?
