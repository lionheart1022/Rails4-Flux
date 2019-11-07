# These Rake tasks will eventually replace the ones placed under lib/monthly_invoicing_report.rake

namespace :invoicing_report do
  desc "Generate invoicing report for the specified year-month"
  task :build_for_month, [:year, :month] => [:environment] do |t, args|
    year = nil
    month = nil

    begin
      year = Integer(args[:year])
    rescue ArgumentError => e
      abort "Year is not a valid integer (#{e.message})"
    rescue TypeError => e
      abort "Year is not specified (#{e.message})"
    end

    begin
      month = Integer(args[:month])
    rescue ArgumentError => e
      abort "Month is not a valid integer (#{e.message})"
    rescue TypeError => e
      abort "Month is not specified (#{e.message})"
    end

    begin
      date = Date.new(year, month)
    rescue ArgumentError => e
      abort "Year+month combination is not valid (#{e.message})"
    end

    first_day_in_month = date.beginning_of_month
    last_day_in_month = date.end_of_month

    invoicing_report = InvoicingReport.new(from: first_day_in_month, to: last_day_in_month)
    csv_string = invoicing_report.produce_csv

    puts
    puts "=" * 80
    puts
    puts csv_string
    puts
    puts "=" * 80
  end

  desc "Generate invoicing report for the past month"
  task :build_for_past_month, [] => [:environment] do
    today = Date.today
    from, to =
      if today.day > 20
        [today.beginning_of_month, today.end_of_day]
      else
        [today.last_month.beginning_of_month, today.last_month.end_of_month]
      end

    invoicing_report = InvoicingReport.new(from: from, to: to)
    csv_string = invoicing_report.produce_csv

    puts
    puts "=" * 80
    puts
    puts csv_string
    puts
    puts "=" * 80
  end
end
