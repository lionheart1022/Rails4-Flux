require "test_helper"

class CarrierTest < ActiveSupport::TestCase
  test "when name is not specified it should return name of parent" do
    parent_carrier = Carrier.create!(name: "Parent Carrier")
    carrier = Carrier.create!(name: nil, carrier: parent_carrier)

    assert_not_equal carrier[:name], parent_carrier[:name]
    assert_equal parent_carrier.name, carrier.name
  end

  test "when name is specified it should not return name of parent" do
    parent_carrier = Carrier.create!(name: "Parent Carrier")
    carrier = Carrier.create!(name: "Not Parent Carrier", carrier: parent_carrier)

    assert_not_equal carrier.name, parent_carrier.name
    assert_equal carrier[:name], carrier.name
  end
end
