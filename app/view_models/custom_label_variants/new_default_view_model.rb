module CustomLabelVariants
  class NewDefaultViewModel < SimpleDelegator
    attr_reader :current_context

    def initialize(shipment:, current_context:)
      @current_context = current_context
      super(shipment)
    end

    def logo_url
      shipment.product_responsible && shipment.product_responsible.asset_logo && shipment.product_responsible.asset_logo.attachment.url
    end

    def label_header
      "#{shipment.product_responsible.name} - Reference ##{shipment.unique_shipment_id}"
    end

    def label_number(index)
      "#{index + 1} of #{number_of_labels}"
    end

    def number_of_labels
      shipment.package_dimensions.dimensions.count
    end

    def main_view
      "components/custom_label_variants/new_default"
    end

    private

    def shipment
      __getobj__
    end
  end
end
