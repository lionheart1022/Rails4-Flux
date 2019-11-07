FactoryBot.define do
  factory :sender do
    attention { "Jannick Sloth" }
    company_name { "CargoFlux ApS" }
    phone_number { "+45 12 34 56 78" }
    email { "jannick.sloth@cargoflux.com" }
    address_line1 { "Njalsgade 17A" }
    address_line2 { "Islands Brygge" }
    zip_code { "2300" }
    city { "Copenhagen" }
    country_code { "dk" }
    country_name { "Denmark" }
  end

  factory :sender_from_sweden, parent: :sender do
    address_line1 { "Sodergatan 512" }
    zip_code { "21766" }
    city { "Malmo" }
    country_code { "se" }
    country_name { "Sweden" }
  end

  factory :sender_from_usa, parent: :sender do
    address_line1 { "1202 Chalet Ln" }
    address_line2 { "Do Not Delete - Test Account" }
    zip_code { "72601" }
    city { "Harrison" }
    state_code { "AR" }
    country_code { "us" }
    country_name { "United States" }
  end
end
