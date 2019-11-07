namespace :product_codes do
  desc "Get all product codes"
  task list: :environment do
    columns = [
      :product_code,
      :product_name,
      :carrier_name,
      :company,
    ]

    header_row = {
      product_code: "Product code",
      product_name: "Carrier product",
      carrier_name: "Carrier",
      company: "Company",
    }

    csv_string = CSV.generate(col_sep: ";", headers: header_row.values_at(*columns), write_headers: true) do |csv|
      carrier_products =
        CarrierProduct
        .where.not(product_code: nil)
        .where.not(product_code: "")
        .where(carrier_product_id: nil) # I guess we should only consider the base products, first product in chain
        .includes(:carrier, :company)

      carrier_products.each do |carrier_product|
        row = {
          product_code: carrier_product.product_code,
          product_name: carrier_product.name,
          carrier_name: carrier_product.carrier.name,
          company: carrier_product.company.try(:name),
        }

        csv << row.values_at(*columns)
      end
    end

    puts "=" * 80
    puts
    puts csv_string
    puts
    puts "=" * 80
  end
end
