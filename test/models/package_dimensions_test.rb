require "test_helper"

class PackageDimensionsTest < ActiveSupport::TestCase
  test "when equal" do
    a = PackageDimensions.new(dimensions: [
      PackageDimension.new(length: 10, width: 10, height: 10, weight: 10, volume_weight: 0),
      PackageDimension.new(length: 20, width: 20, height: 10, weight: 10, volume_weight: 0),
      PackageDimension.new(length: 10, width: 10, height: 10, weight: 10, volume_weight: 0),
    ])
    b = PackageDimensions.new(dimensions: [
      PackageDimension.new(length: 20, width: 20, height: 10, weight: 10, volume_weight: 0),
      PackageDimension.new(length: 10, width: 10, height: 10, weight: 10, volume_weight: 0),
      PackageDimension.new(length: 10, width: 10, height: 10, weight: 10, volume_weight: 0),
    ])

    assert a.equal_to?(b)
  end

  test "when volume weight is not equal" do
    a = PackageDimensions.new(dimensions: [
      PackageDimension.new(length: 10, width: 10, height: 10, weight: 10, volume_weight: 0),
      PackageDimension.new(length: 20, width: 20, height: 10, weight: 10, volume_weight: 2),
      PackageDimension.new(length: 10, width: 10, height: 10, weight: 10, volume_weight: 0),
    ])
    b = PackageDimensions.new(dimensions: [
      PackageDimension.new(length: 20, width: 20, height: 10, weight: 10, volume_weight: 7),
      PackageDimension.new(length: 10, width: 10, height: 10, weight: 10, volume_weight: 0),
      PackageDimension.new(length: 10, width: 10, height: 10, weight: 10, volume_weight: 0),
    ])

    refute a.equal_to?(b)
  end

  test "when not equal" do
    a = PackageDimensions.new(dimensions: [
      PackageDimension.new(length: 10, width: 10, height: 10, weight: 10, volume_weight: 0),
      PackageDimension.new(length: 20, width: 20, height: 10, weight: 10, volume_weight: 0),
    ])
    b = PackageDimensions.new(dimensions: [
      PackageDimension.new(length: 20, width: 20, height: 10, weight: 10, volume_weight: 0),
      PackageDimension.new(length: 10, width: 10, height: 10, weight: 10, volume_weight: 0),
      PackageDimension.new(length: 10, width: 10, height: 10, weight: 10, volume_weight: 0),
    ])

    refute a.equal_to?(b)
  end

  test "when not equal with same length" do
    a = PackageDimensions.new(dimensions: [
      PackageDimension.new(length: 10, width: 10, height: 10, weight: 10, volume_weight: 0),
    ])
    b = PackageDimensions.new(dimensions: [
      PackageDimension.new(length: 20, width: 20, height: 10, weight: 10, volume_weight: 0),
    ])

    refute a.equal_to?(b)
  end
end
