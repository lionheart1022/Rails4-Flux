require "csv"

# This module is currently just used for debugging purposes. When the UPS
# updates functionality works as intended this file and the related Rake tasks
# can be deleted.

module UPSBillingReport
  HEADERS = [
    "account_number",
    "awb",
    "shipment_ref1",
    "shipment_ref2",
    "pkg_tracking_number",
    "pkg_actual_weight",
    "pkg_actual_weight_unit",
    "pkg_surcharges",
  ]

  class << self
    def print_from_zip_result(zip_result)
      zip_result.each do |file_name, parse_result|
        puts
        puts "# #{file_name}"
        puts "-" * 80
        print_result(parse_result)
      end
    end

    def print_result(parse_result)
      csv = CSV.new('', col_sep: ";", write_headers: true, headers: HEADERS)

      non_cf_shipment_count = 0

      parse_result.each do |_, shipment_entry|
        shipment_entry[:packages].each do |_, package_entry|
          if shipment_entry[:shipment_reference_1].to_s.start_with?("CF-")
            # Great!
          else
            non_cf_shipment_count += 1
            next
          end

          row_attrs = {
            "account_number" => shipment_entry[:account_number],
            "awb" => shipment_entry[:lead_shipment_number],
            "shipment_ref1" => shipment_entry[:shipment_reference_1],
            "shipment_ref2" => shipment_entry[:shipment_reference_2],
            "pkg_tracking_number" => package_entry[:pkg_tracking_number],
            "pkg_actual_weight" => package_entry[:pkg_actual_weight],
            "pkg_actual_weight_unit" => package_entry[:pkg_actual_weight_unit],
            "pkg_surcharges" => package_entry[:pkg_surcharges].map(&:inspect).join(","),
          }

          csv_row = CSV::Row.new(HEADERS, row_attrs.values_at(*HEADERS))
          csv.add_row(csv_row)
        end
      end

      print csv.string
      puts "/" * 80
      puts "Shipments created outside of CF: #{non_cf_shipment_count}"
      puts "Total parsed shipments: #{parse_result.length}"
    end
  end
end
