FactoryBot.define do
  factory :advanced_price do
    cost_price_currency { "DKK" }
    sales_price_currency { "DKK" }
    trait :with_line_items do
      after(:create) do |ap|
        create_list :advanced_price_line_item, 2, advanced_price: ap
      end
    end
  end
end
