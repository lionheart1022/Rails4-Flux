class PackageDimensionsFormParams
  attr_accessor :package_dimensions_params

  def initialize(package_dimensions_params)
    self.package_dimensions_params = package_dimensions_params
  end

  def as_array
    dimensions =
      if package_dimensions_params.is_a?(Array)
        package_dimensions_params
      else
        package_dimensions_params.values
      end

    dimensions.flat_map do |dimension|
      amount = dimension[:amount].to_i

      amount.times.map do |i|
        PackageDimension.new(
          length: dimension[:length].to_i,
          width: dimension[:width].to_i,
          height: dimension[:height].to_i,
          weight: dimension[:weight].gsub(',', '.').to_f,
        )
      end
    end
  end

  def as_package_dimensions_object
    PackageDimensions.new(dimensions: as_array)
  end
end
