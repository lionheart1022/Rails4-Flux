require "test_helper"

class TruckTest < ActiveSupport::TestCase
  test "#find_or_create_active_delivery" do
    truck = FactoryBot.create(:truck)

    truck.find_or_create_active_delivery

    assert_not truck.active_delivery.nil?
  end
end
