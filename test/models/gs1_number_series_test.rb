require "test_helper"

class GS1NumberSeriesTest < ActiveSupport::TestCase
  test ".next_sscc_number! raises when no active series is found" do
    assert_raises StandardError do
      GS1NumberSeries.next_sscc_number!
    end

    GS1NumberSeries.create!(disabled_at: Time.zone.now, max_value: 10, our_prefix: "3", gs1_prefix: "5712345")

    assert_raises StandardError do
      GS1NumberSeries.next_sscc_number!
    end
  end

  test ".next_sscc_number! generates a new number" do
    GS1NumberSeries.create!(max_value: 10, our_prefix: "3", gs1_prefix: "5712345")

    n1 = GS1NumberSeries.next_sscc_number!
    n2 = GS1NumberSeries.next_sscc_number!

    assert n1
    assert n2
    assert n1 != n2
  end
end
