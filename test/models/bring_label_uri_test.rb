require "test_helper"

class BringLabelURITest < ActiveSupport::TestCase
  test "label URI can be parsed" do
    label_url = "https://api.bring.com/labels/id/ce961036-9570-4581-b784-514c93c43f30.pdf#zoom=100[,0,0]"

    assert_nothing_raised { URI::DEFAULT_PARSER.parse(label_url) }
  end
end
