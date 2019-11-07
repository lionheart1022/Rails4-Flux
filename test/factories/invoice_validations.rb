FactoryBot.define do
  factory :invoice_validation do
    company
    shipment_id_column { "B1" }
    cost_column { "D1" }
  end
end
