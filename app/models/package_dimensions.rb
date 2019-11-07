require 'bigdecimal'
require 'package_dimension'

class PackageDimensions
  attr_reader :dimensions, :volume_type

  module VolumeTypes
    LOADING_METER = 'loading_meter'
    VOLUME_WEIGHT = 'volume_weight'
  end

  def initialize(dimensions: [], volume_type: nil)
    @dimensions = dimensions
    @volume_type = volume_type
  end

  def loading_meter?
    @volume_type == VolumeTypes::LOADING_METER
  end

  def total_weight
    @dimensions.sum do |dimension|
      dimension.weight
    end
  end

  def total_rounded_weight(n)
    @dimensions.sum do |dimension|
      dimension.weight.nil? ? 0 : BigDecimal(dimension.weight.round(n), Float::DIG)
    end.to_f.round(n)
  end

  def total_volume_weight
    @dimensions.sum do |dimension|
      dimension.volume_weight.nil? ? 0 : BigDecimal(dimension.volume_weight, Float::DIG)
    end
  end

  def total_aggregated_and_rounded_volume_weight(n)
    aggregate.sum do |dimension|
      dimension.volume_weight.nil? ? 0.0 : (dimension.amount * dimension.volume_weight.round(n))
    end
  end

  def total_volume
    @dimensions.sum do |dimension|
      dimension.volume
    end
  end

  def number_of_packages
    @dimensions.sum{ |dim| 1 }
  end

  def equal_to?(other)
    grouped_dimensions = dimensions.group_by(&:equality_key)
    other_grouped_dimensions = other.dimensions.group_by(&:equality_key)

    return false if grouped_dimensions.keys.count != other_grouped_dimensions.keys.count

    grouped_dimensions.each do |equality_key, left|
      right = other_grouped_dimensions[equality_key]

      return false if right.nil?
      return false if left.count != right.count
    end

    true
  end

  def equal(package_dimensions)
    left  = self.dup.aggregate
    right = package_dimensions.dup.aggregate

    return false if left.length != right.length

    left.zip(right).all? do |left, right|
      (left.length        == right.length) &&
      (left.width         == right.width) &&
      (left.height        == right.height) &&
      (left.weight        == right.weight) &&
      (left.volume_weight == right.volume_weight) &&
      (left.amount        == right.amount)
    end
  end

  def aggregate
    hash = Hash.new
    @dimensions.each do |dimension|
      if hash.keys.include?(dimension.key)
        hash[dimension.key].amount += 1
      else
        dimension.amount = 1
        hash[dimension.key] = dimension
      end
    end
    return hash.values
  end
end
