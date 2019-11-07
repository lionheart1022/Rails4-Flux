class TNTPriceDocument < PriceDocumentV1

  class ImportCharge < LogicalCharge

    def calculate(weight: nil, base: nil, package_dimensions: nil, import: nil)
      import ? amount : 0
    end

  end

end
