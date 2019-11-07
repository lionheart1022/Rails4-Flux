FactoryBot.define do
  factory :package_dimension do
    skip_create

    length { 10 }
    width { 20 }
    height { 30 }
    weight { 50 }
    volume_weight { 100 }

    initialize_with do
      new(
        length: length,
        width: width,
        height: height,
        weight: weight,
        volume_weight: volume_weight
      )
    end
  end
end
