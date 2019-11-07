require "test_helper"

class RouteCalculationTest < ActiveSupport::TestCase
  test "calculating shortest route" do
    from = Address.new(country_code: "dk", zip_code: "2300", city: "København S", address_line1: "Njalsgade 17A, 2")
    to = Address.new(country_code: "dk", zip_code: "4700", city: "Næstved", address_line1: "Banegårdspladsen 2")

    d = RouteCalculation.new(from: from, to: to).shortest_distance_in_km(client: FakeDirections)
    assert_equal 90.0, d
  end

  test "error handling" do
    from = Address.new(country_code: "dk", zip_code: "2300", city: "København S", address_line1: "Njalsgade 17A, 2")
    to = Address.new(country_code: "tr", zip_code: "1234", city: "Læstved", address_line1: "Flotvej")

    assert_nil RouteCalculation.new(from: from, to: to).shortest_distance_in_km(client: FakeDirectionsWithError.new(error: RouteCalculation::NotFoundError.new("Raise this")))
    assert_nil RouteCalculation.new(from: from, to: to).shortest_distance_in_km(client: FakeDirectionsWithError.new(error: RouteCalculation::NoRouteError.new("Raise this")))
  end

  module FakeDirections
    module_function
      def shortest_distance_in_m(from:, to:)
        90_000
      end
  end

  class FakeDirectionsWithError
    def initialize(error:)
      @error = error
    end

    def shortest_distance_in_m(from:, to:)
      raise @error
    end
  end
end
