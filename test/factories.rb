FactoryBot.define do
  factory :truck do
    sequence(:name) { |n| "truck#{n}" }
    after(:build) do |truck|
      truck.company ||= build(:company)
    end
  end

  factory :truck_driver do
    sequence(:name) { |n| "truck_driver#{n}" }
    after(:build) do |truck_driver|
      truck_driver.company ||= build(:company)
    end
  end

  # Generate random margin percentage for sales prices
  #
  sequence(:margin_percentage) do |n|
    @margin_percentage ||= (10..30).to_a.shuffle
    @margin_percentage[n]
  end

  #
  # -------------- Factories ---------------
  #

  # Customer
  #
  factory :customer do
    sequence(:name) { |n| "customer_name#{n}" }

    after(:build) do |customer|
      customer.company ||= build(:company)
    end
  end

  # Company
  #
  factory :company do
    sequence(:name) { |n| "company_name#{n}" }
    trait :as_carrier_product_owner do
      after(:create) do |company|
        create_list(:carrier_product, 1, company: company)
      end
    end
  end

  # Carrier
  #
  factory :carrier do
    sequence(:name) { |n| "company_name#{n}" }
  end

  # Customer Carrier Product
  #
  factory :customer_carrier_product do
    is_disabled { false }

    after(:build) do |ccp|
      ccp.carrier_product ||= build(:carrier_product)
      ccp.customer        ||= build(:customer)
      ccp.sales_price     ||= build(:sales_price, reference: ccp)
    end

  end


  # Carrier Product Price (TNT Express)
  #
  factory :carrier_product_price do
    state { 'ok' }
    price_document { TestPriceDocuments.tnt_express }

    after(:build) do |cpp|
      cpp.carrier_product ||= build(:carrier_product, carrier_product_price: cpp)
    end
  end

  # Sales Price
  #
  factory :sales_price do
    margin_percentage { 10.0 }

    factory :carrier_product_sales_price do

      after(:build) do |sp|
        sp.reference ||= build(:reference, sales_price: sp)
      end

    end

  end
end
