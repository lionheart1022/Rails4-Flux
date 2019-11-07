class Shared::CustomLabel
	attr_reader :current_company, :shipment, :sender, :recipient, :main_view

	def initialize(current_company: nil, shipment: nil, sender: nil, recipient: nil)
		@current_company = current_company
		@shipment        = shipment
		@sender          = sender
		@recipient       = recipient
		state_general
	end

	def weight_with_metric(weight)
		"#{weight} KG"
	end

	def label_header
		"#{@shipment.product_responsible.name} - Reference ##{shipment.unique_shipment_id}"
	end

	def carrier_product_name
		shipment.carrier_product.name
	end

	def label_number(index)
		"#{index + 1} of #{number_of_labels}"
	end

	def format_dimension(dimension)
		"Length: #{dimension.length} cm, Width: #{dimension.width} cm, Height: #{dimension.height} cm"
	end

	def truncate(string, amount)
		string.try(:truncate, amount)
	end

	def logo_url
		@shipment.product_responsible && @shipment.product_responsible.asset_logo && @shipment.product_responsible.asset_logo.attachment.url
	end

  def remarks
    shipment.remarks
  end

	private

	def state_general
    @main_view = "components/shared/shipments/custom_label"
  end

  def number_of_labels
		shipment.package_dimensions.dimensions.count
	end

end
