class ScandlinesCarrierProduct < CarrierProduct
  # We don't want Scandlines to appear in the available products so it will always be non-eligible.
  # This Scandlines carrier product is special and only used as a placeholder for ferry bookings.
  def eligible?(sender_country_code: nil, destination_country_code: nil, import: nil, number_of_packages: nil)
    false
  end
end
