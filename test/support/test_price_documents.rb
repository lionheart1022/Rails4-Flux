require "tempfile"

module TestPriceDocuments
  mattr_accessor :_tnt_express
  mattr_accessor :_freja_dk_pallet
  mattr_accessor :_price_single_multi_zone_dk
  mattr_accessor :_price_single_1kg_single_zone_dk
  mattr_accessor :_price_single_1kg_single_zone_dk_per_package
  mattr_accessor :_price_single_1kg_single_zone_dk_with_surcharge

  class << self
    def tnt_express
      self._tnt_express ||= ExcelToPriceDocumentParser.new.parse(price_document_class: TNTPriceDocument, filename: "test/price_documents/tnt_express_final.xlsx")
    end

    def freja_dk_pallet
      self._freja_dk_pallet ||= ExcelToPriceDocumentParser.new.parse(price_document_class: PriceDocumentV1, filename: "test/price_documents/freja_dk_final.xlsx")
    end

    def price_single_multi_zone_dk
      self._price_single_multi_zone_dk ||= begin
        file = Tempfile.new(["test-price-document", ".xlsx"], Rails.root.join("tmp"))
        price_document = nil

        begin
          workbook = WriteXLSX.new(file.path)

          zones_worksheet = workbook.add_worksheet("zones")
          zones_worksheet.write_col("A1", [
            ["Country code", "Country", "Zone", "Zip codes"],
            ["DK",           "Denmark", "1",    "2300"],
            ["DK",           "Denmark", "2",    "2700"],
          ])

          prices_worksheet = workbook.add_worksheet("prices")
          prices_worksheet.write_col("A1", [
            ["Currency", "Calculation basis"],
            ["DKK", "shipment"],

            ["Charge type",     "Name", "Calculation method", "Description", "Weight (kg)", "1", "2"],
            ["shipment_charge", nil,    "price_single",       nil,           1,             90,  120],
            [nil,               nil,    "price_single",       nil,           1.5,           100, 150],
          ])

          workbook.close

          price_document = ExcelToPriceDocumentParser.new.parse(price_document_class: PriceDocumentV1, filename: file.path)
        ensure
          file.close
          file.unlink
        end

        price_document
      end
    end

    def price_single_1kg_single_zone_dk
      self._price_single_1kg_single_zone_dk ||= begin
        file = Tempfile.new(["test-price-document", ".xlsx"], Rails.root.join("tmp"))
        price_document = nil

        begin
          workbook = WriteXLSX.new(file.path)

          zones_worksheet = workbook.add_worksheet("zones")
          zones_worksheet.write_col("A1", [
            ["Country code", "Country", "Zone", "Zip codes"],
            ["DK", "Denmark", "1", nil]
          ])

          prices_worksheet = workbook.add_worksheet("prices")
          prices_worksheet.write_col("A1", [
            ["Currency", "Calculation basis"],
            ["DKK", "shipment"],

            ["Charge type",     "Name", "Calculation method", "Description", "Weight (kg)", "1"],
            ["shipment_charge", nil,    "price_single",       nil,           1,             90],
            [nil,               nil,    "price_single",       nil,           1.5,           100],
          ])

          workbook.close

          price_document = ExcelToPriceDocumentParser.new.parse(price_document_class: PriceDocumentV1, filename: file.path)
        ensure
          file.close
          file.unlink
        end

        price_document
      end
    end

    def price_single_1kg_single_zone_dk_per_package
      self._price_single_1kg_single_zone_dk_per_package ||= begin
        file = Tempfile.new(["test-price-document", ".xlsx"], Rails.root.join("tmp"))
        price_document = nil

        begin
          workbook = WriteXLSX.new(file.path)

          zones_worksheet = workbook.add_worksheet("zones")
          zones_worksheet.write_col("A1", [
            ["Country code", "Country", "Zone", "Zip codes"],
            ["DK", "Denmark", "1", nil]
          ])

          prices_worksheet = workbook.add_worksheet("prices")
          prices_worksheet.write_col("A1", [
            ["Currency", "Calculation basis"],
            ["DKK", "package"],

            ["Charge type",     "Name", "Calculation method", "Description", "Weight (kg)", "1"],
            ["shipment_charge", nil,    "price_single",       nil,           1,             90],
            [nil,               nil,    "price_single",       nil,           1.5,           100],
          ])

          workbook.close

          price_document = ExcelToPriceDocumentParser.new.parse(price_document_class: PriceDocumentV1, filename: file.path)
        ensure
          file.close
          file.unlink
        end

        price_document
      end
    end

    def price_single_1kg_single_zone_dk_with_surcharge
      self._price_single_1kg_single_zone_dk_with_surcharge ||= begin
        file = Tempfile.new(["test-price-document", ".xlsx"], Rails.root.join("tmp"))
        price_document = nil

        begin
          workbook = WriteXLSX.new(file.path)

          zones_worksheet = workbook.add_worksheet("zones")
          zones_worksheet.write_col("A1", [
            ["Country code", "Country", "Zone", "Zip codes"],
            ["DK", "Denmark", "1", nil]
          ])

          prices_worksheet = workbook.add_worksheet("prices")
          prices_worksheet.write_col("A1", [
            ["Currency", "Calculation basis"],
            ["DKK", "shipment"],

            ["Charge type",     "Name",        "Calculation method", "Description", "Weight (kg)", "1"],
            ["shipment_charge", nil,           "price_single",       nil,           1,             90],
            [nil,               nil,           "price_single",       nil,           1.5,           100],
            ["surcharge",       "Miljø gebyr", "price_fixed",        nil,           nil,           40],
          ])

          workbook.close

          price_document = ExcelToPriceDocumentParser.new.parse(price_document_class: PriceDocumentV1, filename: file.path)
        ensure
          file.close
          file.unlink
        end

        price_document
      end
    end
  end
end
