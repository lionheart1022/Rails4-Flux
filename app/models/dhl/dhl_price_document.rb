class DHLPriceDocument < PriceDocumentV1

	class HeavyPackageCharge < LogicalCharge

    def calculate(weight: nil, base: nil, package_dimensions: nil, import: nil)
      total = 0
      package_dimensions.dimensions.each do |dimension|
        total += dimension.weight > threshold ? amount : 0
      end
      total
    end

	end

	class LargePackageCharge < LogicalCharge

    def calculate(weight: nil, base: nil, package_dimensions: nil, import: nil)
      total = 0
      package_dimensions.dimensions.each do |dimension|
    	  dimensions = [dimension.height, dimension.width, dimension.length]
    	  total += dimensions.any?{ |dim| dim > threshold} ? amount : 0
      end
      total
    end

	end

end