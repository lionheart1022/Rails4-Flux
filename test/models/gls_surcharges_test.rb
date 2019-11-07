require "test_helper"

class GLSSurchargesTest < ActiveSupport::TestCase
  test "surcharges are applied after receiving updates from carrier" do
    company = Company.create!(name: "We-Sell-Freight")
    carrier = GLSCarrier.create!(name: "GLS")
    carrier_product = GLSPrivateCarrierProduct.create!(name: "GLS Private", carrier: carrier, company: company, state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
    carrier_product.set_credentials(credentials: { :customer_id => "2080010973" })
    carrier_product.create_carrier_product_price!(price_document: TestPriceDocuments.price_single_1kg_single_zone_dk_per_package, state: "ok")
    customer = Customer.create!(name: "We-Buy-Freight", company: company)
    customer_carrier_product = CustomerCarrierProduct.create!(customer: customer, carrier_product: carrier_product)
    customer_carrier_product.create_sales_price!(margin_percentage: "20")

    package_dimensions = PackageDimensionsBuilder.build(carrier_product: carrier_product) do |builder|
      builder.add_package(length: 10, width: 10, height: 10, weight: 1)
      builder.add_package(length: 20, width: 20, height: 20, weight: 1.5)
    end

    SurchargeOnCarrier.create!(carrier: carrier, surcharge: GLSSurcharges::NotSystemConformal.create!(description: "GLS Not System Conform surcharge", calculation_method: "price_fixed", charge_value: "100"))
    SurchargeOnCarrier.create!(carrier: carrier, surcharge: GLSSurcharges::OverSize.create!(description: "GLS Over Size surcharge", calculation_method: "price_fixed", charge_value: "50"))

    shipment = Shipment.new(company: company, customer: customer, carrier_product: carrier_product)
    shipment.package_dimensions = package_dimensions
    shipment.number_of_packages = 2
    shipment.shipping_date = Date.today
    shipment.sender = FactoryBot.create(:sender, country_code: "dk")
    shipment.recipient = FactoryBot.create(:recipient, country_code: "dk")
    shipment.advanced_prices = ShipmentPriceCalculation.calculate(
      company_id: shipment.company_id,
      customer_id: shipment.customer_id,
      carrier_product: shipment.carrier_product,
      sender_country_code: shipment.sender.country_code,
      sender_zip_code: shipment.sender.zip_code,
      recipient_country_code: shipment.recipient.country_code,
      recipient_zip_code: shipment.recipient.zip_code,
      package_dimensions: shipment.package_dimensions,
      distance_in_kilometers: nil,
      dangerous_goods: false,
    )
    shipment.save!

    assert_equal 1, shipment.advanced_prices.size
    assert_equal 2, shipment.advanced_prices[0].advanced_price_line_items.size
    assert_equal BigDecimal("108.00"), shipment.advanced_prices[0].advanced_price_line_items[0].sales_price_amount
    assert_equal BigDecimal("120.00"), shipment.advanced_prices[0].advanced_price_line_items[1].sales_price_amount

    packages = [
      GLSPackage.create!(shipment: shipment, unique_identifier: "01097379671", package_index: 0, metadata: {}),
      GLSPackage.create!(shipment: shipment, unique_identifier: "01097389184", package_index: 1, metadata: {}),
    ]

    shipment.package_dimensions.dimensions.each_with_index do |dimension, index|
      package = packages[index]
      recording = package.recordings.create!(
        weight_value: dimension.weight,
        volume_weight_value: dimension.volume_weight,
        weight_unit: "kg",
        dimensions: {
          "length" => dimension.length,
          "width" => dimension.width,
          "height" => dimension.height,
          "unit" => "cm",
        }
      )

      package.update!(active_recording: recording)
    end

    daily_file = <<-FILE
Pakkenr     ;Kundenr   ;Vægt    ;SmallParcel;IkkeSystemKonform;OverSize
------------;----------;--------;-----------;-----------------;--------
010973796718;2080010973;    1.00;True       ;True             ;False
010973891840;2080010973;    1.50;False      ;False            ;True
    FILE

    feedback_file = GLSFeedbackFile.create!(company: company) do |f|
      f.assign_file_contents(StringIO.new(daily_file.encode("ISO-8859-1")))
    end
    feedback_file.parse!
    feedback_file.package_updates.each(&:apply_change!)

    shipment.reload

    line_items = shipment.advanced_prices[0].advanced_price_line_items.order(:id)

    assert_equal 1, shipment.advanced_prices.size
    assert_equal 4, shipment.advanced_prices[0].advanced_price_line_items.size
    assert_equal BigDecimal("108.00"), line_items[0].sales_price_amount
    assert_equal BigDecimal("120.00"), line_items[1].sales_price_amount
    assert_equal BigDecimal("100.00"), line_items[2].sales_price_amount
    assert_equal "GLS Not System Conform surcharge", line_items[2].description
    assert_equal BigDecimal("50.00"), line_items[3].sales_price_amount
    assert_equal "GLS Over Size surcharge", line_items[3].description
  end
end
