class PostDKPriceDocument < PriceDocumentV1

	class LargePackageCharge < LogicalCharge

    def calculate(weight: nil, base: nil, package_dimensions: nil, import: nil)
    	total = 0
    	package_dimensions.dimensions.each do |dimension|
    		total += dimension.length > threshold ? amount : 0
    	end
    	total
    end

	end

end