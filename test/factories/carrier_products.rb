FactoryBot.define do
  factory :carrier_product do
    sequence(:name) { |n| "name#{n}" }
    type { 'TNTExpressCarrierProduct' }
    is_disabled { false }
    state { 'locked_for_configuring' }

    after(:build) do |cp|
      cp.sales_price ||= build(:carrier_product_sales_price, reference: cp)
      cp.company     ||= build(:company)
      cp.carrier_product_price ||= build(:carrier_product_price, carrier_product: cp)
    end
  end

  factory :unifaun_home_carrier_product, parent: :carrier_product, class: UnifaunMypackHomeCarrierProduct do
    type { 'UnifaunMypackHomeCarrierProduct' }
  end
end
