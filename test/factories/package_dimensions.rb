FactoryBot.define do
  factory :package_dimensions do
    skip_create
    volume_type { 'volume_weight' }
    dimensions {
      [
        build(:package_dimension),
        build(:package_dimension,
              length: 20,
              width: 30,
              height: 40,
              weight: 60)
      ]
    }

    initialize_with do
      new(dimensions: dimensions, volume_type: volume_type)
    end
  end

  factory :single_package_dimensions, parent: :package_dimensions do
    dimensions { [build(:package_dimension)] }
  end
end
