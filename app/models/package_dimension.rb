class PackageDimension
  attr_reader :length, :width, :height, :weight, :volume_weight
  attr_accessor :amount

  module LoadingDimensions
    TRUCK_WIDTH = 240
    STACKABLE_PALLET_WIDTH = 120
  end

  class << self

    def round(float)
      (float * 10).ceil.to_f / 10
    end

  end

  def initialize(length: nil, width: nil, height: nil, weight: nil, volume_weight: nil)
    @length         = length
    @width          = width
    @height         = height
    @weight         = weight
    @volume_weight  = volume_weight
  end

  def weight_in_grams
    @weight * 1000
  end

  def volume
    @length * @width * @height
  end

  # Units in cm/kg
  #
  def loading_meter(factor)
    factored_minimum = weight.fdiv(factor)

    calculation = (width * length).fdiv(LoadingDimensions::TRUCK_WIDTH).fdiv(100)
    result = calculation < factored_minimum ? factored_minimum : calculation
  end

  # Determines if a pallet can be placed next to each other relative to the width of the truck
  #
  def pallet_stackable?
    [width, length].any? { |dim| dim == LoadingDimensions::STACKABLE_PALLET_WIDTH }
  end

  def length_is_largest?
    @length > @width
  end

  def width_is_largest?
    @width > @length
  end

  def largest_side
    [@length, @width].max
  end

  def smallest_side
    [@length, @width].min
  end

  def load_thresholds
    [80, 160, 240]
  end

  def largest_side_rounded
    load_thresholds.sort.detect { |threshold| largest_side <= threshold }
  end

  def key
    "#{@weight}x#{@length}x#{@width}x#{@height}x#{@width}"
  end

  def equality_key
    [
      weight,
      volume_weight,
      length,
      width,
      height,
      width,
    ]
  end

  def total_weight
    amount.present? ? amount * weight : weight
  end

end
