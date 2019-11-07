class GLSPriceDocument < PriceDocumentV1

  class LargePackageCharge < LogicalCharge

    def calculate(weight: nil, base: nil, package_dimensions: nil, import: nil)
      total = 0
      package_dimensions.dimensions.each do |dimension|
        result = 2 * dimension.height + 2 * dimension.width
        if result >= threshold
          total += amount
        end
      end
      total
    end

  end

end
