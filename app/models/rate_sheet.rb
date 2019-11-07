class RateSheet < ActiveRecord::Base
  belongs_to :created_by, class_name: "User", required: false
  belongs_to :company, required: true
  belongs_to :customer_recording, required: true
  belongs_to :carrier_product, required: true
  belongs_to :base_price_document_upload, class_name: "PriceDocumentUpload", required: true

  def build_1_level_margin(customer_carrier_product: nil)
    if customer_carrier_product
      self.margins = { "method" => "1-level" }

      if customer_carrier_product.sales_price.use_margin_percentage?
        margins["value_type"] = "percentage"
        margins["value"] = customer_carrier_product.sales_price.margin_percentage
      else
        margins["value_type"] = "config"
        margins["margin_config_id"] = customer_carrier_product.sales_price.margin_config_id
        margins["price_document_hash"] = customer_carrier_product.sales_price.margin_config.price_document_hash
      end
    end

    margins
  end

  def build_rate_snapshot
    price_document = carrier_product.price_document

    if price_document.nil?
      raise "No price document is associated with product"
    end

    snapshot =
      case margins["value_type"]
      when "percentage"
        RateSnapshot.build!(price_document: price_document, margin_percentage: margins["value"])
      when "config"
        RateSnapshot.build_with_config!(price_document: price_document, margin_config: CarrierProductMarginConfiguration.find(margins["margin_config_id"]))
      else
        raise "Unsupported margin type #{margins['value_type'].inspect}"
      end

    self.rate_snapshot = snapshot.to_json_hash
  end

  def no_change?(other_rate_sheet)
    other_rate_sheet.base_price_document_upload == base_price_document_upload && other_rate_sheet.margins == margins
  end
end
