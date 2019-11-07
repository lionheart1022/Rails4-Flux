require "test_helper"
require "securerandom"

class CarrierProductSetCredentialsTest < ActiveSupport::TestCase
  setup do
    @_original_carrier_products_encryption_password = ENV["CARRIER_PRODUCTS_ENCRYPTION_PASSWORD"]
    ENV["CARRIER_PRODUCTS_ENCRYPTION_PASSWORD"] = "123"
  end

  teardown do
    ENV["CARRIER_PRODUCTS_ENCRYPTION_PASSWORD"] = @_original_carrier_products_encryption_password
  end

  test "set_credentials with regular hash" do
    carrier_product = CarrierProduct.new(name: "Product")
    carrier_product.set_credentials(credentials: { "username" => "U", "password" => "P" })

    # Values have been encrypted with AESCrypt, via them aescrypt gem (v1.0.0)
    encrypted_credentials = {
      "username" => "ymxIWE4JYebWJFA/c7352A==\n",
      "password" => "ssFqZa0TxB7ZuFUwdDtAdA==\n",
    }

    assert carrier_product.persisted?
    assert_equal({ "username" => "U", "password" => "P" }, carrier_product.get_credentials)
    assert_equal encrypted_credentials, carrier_product.credentials
  end

  test "set_credentials encryption is controlled by ENV" do
    carrier_product_a = CarrierProduct.new(name: "Product A")
    carrier_product_a.set_credentials(credentials: { "username" => "U", "password" => "P" })

    # New encryption key
    original_carrier_products_encryption_password = ENV["CARRIER_PRODUCTS_ENCRYPTION_PASSWORD"]
    ENV["CARRIER_PRODUCTS_ENCRYPTION_PASSWORD"] = SecureRandom.uuid

    carrier_product_b = CarrierProduct.new(name: "Product B")
    carrier_product_b.set_credentials(credentials: { "username" => "U", "password" => "P" })

    # Go back to original encryption key
    ENV["CARRIER_PRODUCTS_ENCRYPTION_PASSWORD"] = original_carrier_products_encryption_password

    carrier_product_c = CarrierProduct.new(name: "Product C")
    carrier_product_c.set_credentials(credentials: { "username" => "U", "password" => "P" })

    assert_equal carrier_product_a.credentials, carrier_product_c.credentials
    assert_not_equal carrier_product_a.credentials, carrier_product_b.credentials
    assert_not_equal carrier_product_c.credentials, carrier_product_b.credentials
  end

  test "set_credentials with missing value in hash" do
    carrier_product = CarrierProduct.new
    exception =
      assert_raises(StandardError) do
        carrier_product.set_credentials(credentials: { "username" => "U", "password" => "" })
      end

    assert_equal "Password must be specified", exception.message
  end

  test "set_credentials with missing test-value in hash" do
    carrier_product = CarrierProduct.new(name: "Product")
    carrier_product.set_credentials(credentials: { "username" => "U", "test_password" => "" })
    assert carrier_product.persisted?
  end

  test "set_credentials without parameters" do
    carrier_product = CarrierProduct.new
    assert_raises(StandardError) { carrier_product.set_credentials }
  end

  test "set_credentials with nil" do
    carrier_product = CarrierProduct.new
    assert_raises(StandardError) { carrier_product.set_credentials(credentials: nil) }
  end
end
