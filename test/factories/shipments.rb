FactoryBot.define do
  factory :shipment do
    number_of_packages { 1 }
    shipping_date { Date.today }
    dutiable { false }
    description { "Pretty Chair" }
    reference { 'TX#1337' }
    package_dimensions
    after(:build) do |s|
      s.company ||= build(:company)
      s.customer ||= build(:customer)
      s.carrier_product ||= build(:carrier_product)
    end
    trait :with_advanced_price do
      after(:create) do |s|
        create_list :advanced_price, 1, :with_line_items, seller_id: s.company.id, seller_type: "Company", shipment: s
      end
    end
  end

  factory :dutiable_shipment, parent: :shipment do
    dutiable { true }
    customs_amount { 1500.0 }
    customs_currency { "DKK" }
    customs_code { "010190" }
  end
end
