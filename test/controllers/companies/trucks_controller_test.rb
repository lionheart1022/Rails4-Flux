require "test_helper"

module Companies
  class TrucksControllerTest < ActionController::TestCase
    include Devise::TestHelpers

    setup do
      company = ::Company.create!(name: "Company")
      customer = ::Customer.create!(name: "Customer", company: company)

      user = ::User.create!(company: company, email: "user@example.com", password: "password", confirmed_at: Time.zone.now)
      EmailSettings.build_with_all_set(user: user).save!
      sign_in user
      @current_company = company
    end

    test "should create truck" do
      assert_difference('Truck.count', 1) do
        post :create, truck: { name: 'Test truck' }
      end
      assert_response :redirect
    end

    test "should create truck with default driver" do
      driver = FactoryBot.create(:truck_driver, company: @current_company)
      assert_difference('Truck.count', 1) do
        post :create, truck: { name: 'Test truck', default_driver_id: driver.id }
      end
      assert_equal driver, Truck.last.default_driver
    end

    test "should get index" do
      FactoryBot.create(:truck, company: @current_company)
      FactoryBot.create(:truck, company: @current_company)

      get :index
      assert_response :success
    end

    test "should update truck" do
      truck = FactoryBot.create(:truck, company: @current_company)
      patch :update, id: truck, truck: { name: "updated_truck" }

      assert_response :redirect
      truck.reload
      assert_equal "updated_truck", truck.name
    end

    test "should delete truck" do
      truck = FactoryBot.create(:truck, company: @current_company)
      assert_difference('Truck.enabled.count', -1) do
        delete :destroy, id: truck
      end
      assert_response :redirect
    end
  end
end
