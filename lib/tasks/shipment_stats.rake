namespace :shipment_stats do
  desc "Get number of shipments, number of packages and total weight for a given company in a given year for a specific carrier type"
  task :yearly, [:company_id, :year, :carrier_type] => [:environment] do |t, args|
    abort "Company ID is missing" if args[:company_id].blank?
    abort "Year is missing" if args[:year].blank?
    abort "Carrier type is missing" if args[:carrier_type].blank?

    company = Company.find(args[:company_id])
    start_of_year = DateTime.new(args[:year].to_i, 1, 1)
    end_of_year = start_of_year.end_of_year

    stats = ShipmentStats.new(
      company: company,
      period: start_of_year..end_of_year,
      carrier_type: args[:carrier_type],
    )

    stats.run!

    puts "Company: #{company.name} (id: #{company.id})"
    puts
    puts "#{stats.result.carrier_type}"
    puts "Number of shipments: #{stats.result.number_of_shipments}"
    puts "Number of packages: #{stats.result.number_of_packages}"
    puts "Total weight: #{stats.result.rounded_total_weight} kg"
  end
end
