class CarrierProductOptions
  attr_accessor :basis, :volume_weight_type

  module Basis
    WEIGHT = 'weight'
    DISTANCE = 'distance'
  end

  module VolumeWeightTypes
    VOLUME_WEIGHT = 'volume_weight'
    LOADING_METER = 'loading_meter'
  end

  def initialize(basis: Basis::WEIGHT, volume_weight_type: VolumeWeightTypes::VOLUME_WEIGHT)
    @basis = basis
    @volume_weight_type = volume_weight_type
  end

  # Static
  #
  #

  class << self

    def bases
      constants = Basis.constants.map &:to_s
      constants.map { |constant| Basis.const_get(constant) }
    end

    def volume_weight_types
      constants = VolumeWeightTypes.constants.map &:to_s
      constants.map { |constant| VolumeWeightTypes.const_get(constant) }
    end

  end

  # Instance
  #
  #

  def weight?
    basis == Basis::WEIGHT
  end

  def distance?
    basis == Basis::DISTANCE
  end

  def volume_weight?
    volume_weight_type == VolumeWeightTypes::VOLUME_WEIGHT
  end

  def loading_meter?
    volume_weight_type == VolumeWeightTypes::LOADING_METER
  end

end
