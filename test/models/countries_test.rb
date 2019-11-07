require "test_helper"

class CountriesTest < ActiveSupport::TestCase
  test "Denmark" do
    assert Country["dk"]
  end

  test "Kosovo" do
    assert Country["XK"]
  end
end
