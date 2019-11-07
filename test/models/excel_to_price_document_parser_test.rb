require "test_helper"

class ExcelToPriceDocumentParserTest < ActiveSupport::TestCase
  test "example 1" do
    with_tmp_xlsx_file do |file|
      workbook = WriteXLSX.new(file.path)

      zones_worksheet = workbook.add_worksheet("Zones")
      zones_worksheet.write_col("A1", [
        ["Country code", "Country", "Zone", "Zip codes"],
        ["DK",           "Denmark", "1",    nil        ],
      ])

      prices_worksheet = workbook.add_worksheet("Prices")
      prices_worksheet.write_col("A1", [
        ["Currency", "Calculation basis"],
        ["DKK",      "shipment"         ],

        ["Charge type",     "Name", "Calculation method", "Description", "Weight (kg)", "1"],
        ["shipment_charge", nil,    "price_single",       nil,           1,             7  ],
        [nil,               nil,    "price_single",       nil,           2,             10 ],
        [nil,               nil,    "price_single",       nil,           3,             15 ],
      ])

      workbook.close

      price_document_class = PriceDocumentV1
      price_document = ExcelToPriceDocumentParser.new.parse(price_document_class: price_document_class, filename: file.path)

      assert_equal "ok", price_document.state

      package_dimensions = PackageDimensions.new(
        dimensions: [PackageDimension.new(length: 1, width: 1, height: 1, weight: 2, volume_weight: 0)],
        volume_type: "volume_weight",
      )

      price = price_document.calculate_price_for_shipment(
        sender_country_code: nil,
        sender_zip_code: nil,
        recipient_country_code: "DK",
        recipient_zip_code: nil,
        package_dimensions: package_dimensions,
        margin: 0,
        import: false,
        dangerous_goods: false,
        distance_in_kilometers: nil,
      )

      assert_equal 10.0, price.total
    end
  end

  test "example 2" do
    with_tmp_xlsx_file do |file|
      workbook = WriteXLSX.new(file.path)

      zones_worksheet = workbook.add_worksheet("Zones")
      zones_worksheet.write_col("A1", [
        ["Country code", "Country", "Zone", "Zip codes"],
        ["DK",           "Denmark", "1",    nil        ],
      ])

      prices_worksheet = workbook.add_worksheet("Prices")
      prices_worksheet.write_col("A1", [
        ["Currency", "Calculation basis"],
        ["DKK",      "shipment"         ],

        ["Charge type",     "Name", "Calculation method", "Description", "Weight (kg)", "1" ],
        ["shipment_charge", nil,    "price_weight_range", nil,           1,             7   ],
        [nil,               nil,    nil,                  nil,           5,             nil ],
        [nil,               nil,    nil,                  nil,           0.5,           2   ],
      ])

      workbook.close

      price_document_class = PriceDocumentV1
      price_document = ExcelToPriceDocumentParser.new.parse(price_document_class: price_document_class, filename: file.path)

      assert_equal "ok", price_document.state

      package_dimensions = PackageDimensions.new(
        dimensions: [PackageDimension.new(length: 1, width: 1, height: 1, weight: 3, volume_weight: 0)],
        volume_type: "volume_weight",
      )

      price = price_document.calculate_price_for_shipment(
        sender_country_code: nil,
        sender_zip_code: nil,
        recipient_country_code: "DK",
        recipient_zip_code: nil,
        package_dimensions: package_dimensions,
        margin: 0,
        import: false,
        dangerous_goods: false,
        distance_in_kilometers: nil,
      )

      assert_equal 15.0, price.total
    end
  end

  private

  def with_tmp_xlsx_file
    file = Tempfile.new(["file", ".xlsx"])

    begin
      yield file
    ensure
      file.close
      file.unlink
    end
  end
end
