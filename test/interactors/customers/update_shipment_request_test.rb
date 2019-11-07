require "test_helper"

class Customers::UpdateShipmentRequestTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @company = ::Company.create!(name: "Test Company", initials: "TEST")

    @company_user = User.new(
      email: "test-company-user@example.com",
      password: "password",
      confirmed_at: Time.now,
      company: @company,
      is_customer: false,
    )
    @company_user.build_email_settings
    @company_user.save!

    @customer = ::Customer.create!(name: "Test Customer", company: @company, customer_id: 1)

    @customer_user = User.new(
      email: "test-customer-user@example.com",
      password: "password",
      confirmed_at: Time.now,
      company: @company,
      customer: @customer,
      is_customer: true,
    )
    @customer_user.build_email_settings
    @customer_user.save!

    carrier = Carrier.new(company: @company, name: "Custom Carrier")
    carrier.save!

    carrier_product_params = {
      company_id: @company.id,
      carrier_id: carrier.id,
      name: "Custom Carrier Product",
      custom_label: false,
      product_type: nil,
      product_code: nil,
      options: {},
    }
    @carrier_product = CarrierProduct.create_carrier_product(carrier_product_params)

    CustomerCarrierProduct.create_customer_carrier_product(customer_id: @customer.id, carrier_product_id: @carrier_product.id)
  end

  test "run with accept event" do
    shipment_request = create_shipment_request

    assert_emails 1 do
      run_interactor(shipment_request, state: ShipmentRequest::States::ACCEPTED)
    end

    assert_match /RFQ accepted/i, ActionMailer::Base.deliveries.last.subject
  end

  test "run with decline event" do
    shipment_request = create_shipment_request

    assert_emails 1 do
      run_interactor(shipment_request, state: ShipmentRequest::States::DECLINED)
    end

    assert_match /RFQ declined/i, ActionMailer::Base.deliveries.last.subject
  end

  test "run with cancel event" do
    shipment_request = create_shipment_request

    assert_emails 1 do
      run_interactor(shipment_request, state: ShipmentRequest::States::CANCELED)
    end

    assert_match /RFQ canceled/i, ActionMailer::Base.deliveries.last.subject
    assert_equal 1, ActionMailer::Base.deliveries.last.to.count
    assert_equal @company_user.email, ActionMailer::Base.deliveries.last.to.first
  end

  test "run with invalid state" do
    shipment_request = create_shipment_request

    assert_emails 0 do
      assert_raises ArgumentError do
        run_interactor(shipment_request, state: "not-a-valid-state")
      end
    end
  end

  private

  def create_shipment_request
    package_dimension = PackageDimension.new(length: 10, width: 10, height: 10, weight: 1)
    package_dimension = PackageDimension.new(
      length: package_dimension.length,
      width: package_dimension.width,
      height: package_dimension.height,
      weight: package_dimension.weight,
      volume_weight: @carrier_product.applied_volume_calculation(dimension: package_dimension),
    )

    package_dimensions = PackageDimensions.new(
      dimensions: [package_dimension],
      volume_type: @carrier_product.loading_meter? ? PackageDimensions::VolumeTypes::LOADING_METER : PackageDimensions::VolumeTypes::VOLUME_WEIGHT,
    )

    shipment_data = {
      shipping_date: Date.today,
      carrier_product_id: @carrier_product.id,
      package_dimensions: package_dimensions,
      number_of_packages: package_dimensions.number_of_packages,
      dutiable: false,
      customs_amount: nil,
      customs_currency: nil,
      customs_code: nil,
      description: "A Huge Package",
      reference: nil,
      remarks: nil,
      shipment_type: "export",
      state: Shipment::States::REQUEST,
    }

    sender_data = {
      company_name: "Cargoflux ApS",
      attention: "",
      address_line1: "Njalsgade 17A",
      address_line2: "",
      address_line3: "",
      zip_code: "2300",
      city: "Copenahgen",
      country_code: "DK",
      state_code: "",
      phone_number: "",
      email: "",
      save_sender_in_address_book: false,
    }

    recipient_data = {
      company_name: "",
      attention: "Some Person",
      address_line1: "Some Address 123",
      address_line2: "",
      address_line3: "",
      zip_code: "2300",
      city: "Copenhagen",
      country_code: "DK",
      state_code: "",
      phone_number: "",
      email: "",
      save_recipient_in_address_book: false,
    }

    shipment = Shipment.create_shipment(
      company_id: @company.id,
      customer_id: @customer.id,
      scoped_customer_id: @customer.customer_id,
      shipment_data: shipment_data,
      sender_data: sender_data,
      recipient_data: recipient_data,
      id_generator: @customer,
      advanced_prices: [],
    )

    ShipmentRequest.create(shipment_id: shipment.id)
  end

  def run_interactor(shipment_request, state: nil)
    interactor_params = {
      company_id: @company.id,
      customer_id: @customer.id,
      shipment_request_id: shipment_request.id,
      data: { state: state },
    }
    interactor = Customers::ShipmentRequests::Update.new(interactor_params)
    interactor.run
  end
end
