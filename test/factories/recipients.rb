FactoryBot.define do
  factory :recipient do
    attention { "Henrik Andersen" }
    company_name { "Andersen A/S" }
    phone_number { "+45 98 76 54 32" }
    email { "henrik@andersen.dk" }
    address_line1 { "Florsgade 60, 10.th." }
    zip_code { "2200" }
    city { "Copenhagen" }
    country_code { "dk" }
    country_name { "Denmark" }
  end

  factory :recipient_from_sweden, parent: :recipient do
    address_line1 { "Sodergatan 512" }
    zip_code { "21766" }
    city { "Malmo" }
    country_code { "se" }
    country_name { "Sweden" }
  end

  factory :recipient_from_usa, parent: :recipient do
    address_line1 { "1202 Chalet Ln" }
    address_line2 { "Do Not Delete - Test Account" }
    zip_code { "72601" }
    city { "Harrison" }
    state_code { "AR" }
    country_code { "us" }
    country_name { "United States" }
  end
end
