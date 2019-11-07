class PackageDimensionsBuilder
  attr_reader :carrier_product
  attr_reader :dimensions

  class << self
    def build(carrier_product:, &block)
      dimensions =
        if block_given?
          builder = new(carrier_product: carrier_product)
          builder.instance_eval(&block)
          builder.dimensions
        else
          []
        end

      PackageDimensions.new(
        dimensions: dimensions,
        volume_type: carrier_product.loading_meter? ? PackageDimensions::VolumeTypes::LOADING_METER : PackageDimensions::VolumeTypes::VOLUME_WEIGHT,
      )
    end

    def build_from_package_dimensions_array(carrier_product:, package_dimensions_array:)
      build(carrier_product: carrier_product) do |builder|
        package_dimensions_array.each do |package_dimension|
          builder.add_package(length: package_dimension.length, width: package_dimension.width, height: package_dimension.height, weight: package_dimension.weight)
        end
      end
    end

    def build_and_apply_volume_weight(carrier_product:, package_dimensions:)
      build_from_package_dimensions_array(carrier_product: carrier_product, package_dimensions_array: package_dimensions.dimensions)
    end
  end

  def initialize(carrier_product:)
    @carrier_product = carrier_product
    @dimensions = []
  end

  def add_package(length:, width:, height:, weight:)
    package_dimension = PackageDimension.new(
      length: length,
      width: width,
      height: height,
      weight: weight,
    )

    volume_weight = carrier_product.applied_volume_calculation(dimension: package_dimension)

    @dimensions <<
      PackageDimension.new(
        length: package_dimension.length,
        width: package_dimension.width,
        height: package_dimension.height,
        weight: package_dimension.weight,
        volume_weight: volume_weight,
      )
  end
end
