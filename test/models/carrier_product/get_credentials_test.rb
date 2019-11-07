require "test_helper"
require "securerandom"

class CarrierProductGetCredentialsTest < ActiveSupport::TestCase
  setup do
    @_original_carrier_products_encryption_password = ENV["CARRIER_PRODUCTS_ENCRYPTION_PASSWORD"]
    ENV["CARRIER_PRODUCTS_ENCRYPTION_PASSWORD"] = "123"
  end

  teardown do
    ENV["CARRIER_PRODUCTS_ENCRYPTION_PASSWORD"] = @_original_carrier_products_encryption_password
  end

  test "get_credentials without state" do
    credentials = { some_field: "SomeValue" }

    carrier_product = CarrierProduct.new(name: "Product")
    carrier_product.set_credentials(credentials: credentials)

    assert carrier_product.persisted?
    assert_equal credentials, carrier_product.get_credentials
  end

  test "get_credentials for locked product with unlocked parent product" do
    credentials = { some_field: "SomeValue" }

    carrier_product_parent = CarrierProduct.create!(name: "Product", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
    carrier_product_parent.set_credentials(credentials: credentials)

    carrier_product_child = CarrierProduct.create!(carrier_product: carrier_product_parent, state: CarrierProduct::States::LOCKED_FOR_CONFIGURING)
    carrier_product_child.set_credentials(credentials: { some_field: "SomeOtherValue" })

    assert_equal(credentials, carrier_product_child.get_credentials)
  end

  test "get_credentials for unlocked product with unlocked parent product" do
    parent_credentials = { some_field: "SomeValue" }
    child_credentials = { some_field: "SomeOtherValue" }

    carrier_product_parent = CarrierProduct.create!(name: "Product", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
    carrier_product_parent.set_credentials(credentials: parent_credentials)

    carrier_product_child = CarrierProduct.create!(carrier_product: carrier_product_parent, state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
    carrier_product_child.set_credentials(credentials: child_credentials)

    assert_equal(child_credentials, carrier_product_child.get_credentials)
  end

  test "get_credentials with locked-state" do
    credentials = { some_field: "SomeValue" }

    carrier_product = CarrierProduct.create!(name: "Product", state: CarrierProduct::States::LOCKED_FOR_CONFIGURING)
    carrier_product.set_credentials(credentials: credentials)

    assert_equal({}, carrier_product.get_credentials)
  end

  test "get_credentials with unlocked-state" do
    credentials = { some_field: "SomeValue" }

    carrier_product = CarrierProduct.create!(name: "Product", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
    carrier_product.set_credentials(credentials: credentials)

    assert_equal credentials, carrier_product.get_credentials
  end

  test "get_credentials with unlocked-state and invalid encryption key" do
    credentials = { some_field: "SomeValue" }

    carrier_product = CarrierProduct.create!(name: "Product", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
    carrier_product.set_credentials(credentials: credentials)

    ENV["CARRIER_PRODUCTS_ENCRYPTION_PASSWORD"] = SecureRandom.uuid

    assert_raises { carrier_product.get_credentials }
  end

  test "get_credentials expects AESCrypt" do
    carrier_product = CarrierProduct.new(name: "Product")
    carrier_product.credentials = {
      "username" => "ymxIWE4JYebWJFA/c7352A==\n",
      "password" => "ssFqZa0TxB7ZuFUwdDtAdA==\n",
    }

    assert_equal({ "username" => "U", "password" => "P" }, carrier_product.get_credentials)
  end
end
