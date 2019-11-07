require "test_helper"

class AddressTest < ActiveSupport::TestCase
  test "to_flat_string" do
    assert_equal "Denmark 2650 Hvidovre Vej 1", Address.new(country_code: "dk", state_code: nil, city: "Hvidovre", zip_code: "2650", address_line1: "Vej 1", address_line2: nil).to_flat_string
    assert_equal "2650 Hvidovre", Address.new(country_code: nil, state_code: nil, city: "Hvidovre", zip_code: "2650", address_line1: "", address_line2: nil).to_flat_string
  end
end
