module ShipmentHelper
  def link_to_cancel_shipment
    case params["controller"]
    when "companies/shipments"
      link_to "Cancel", companies_shipments_path
    when "companies/shipment_requests", "companies/shipment_requests_v2"
      link_to "Cancel", companies_shipment_requests_path
    when "customers/shipments"
      link_to "Cancel", customers_shipments_path
    when "customers/shipment_requests"
      link_to "Cancel", customers_shipment_requests_path
    else
      ExceptionMonitoring.report_message("ShipmentHelper#link_to_cancel_shipment called in unknown context", context: { "controller" => params["controller"], "action" => params["action"] })

      # Fall back to the old behavior
      link_to "Cancel", customers_shipments_path
    end
  end

  def product_selection_carrier_product_metadata(cp)
    prebook_url =
      case params["controller"]
      when "companies/shipments"
        companies_shipment_prebook_checks_path(format: "json")
      when "customers/shipments"
        customers_shipment_prebook_checks_path(format: "json")
      end

    metadata =
      if prebook_url
        {
          "prebook_step" => cp[:carrier_product_prebook_step],
          "prebook_url" => prebook_url,
        }
      else
        {}
      end

    content_tag(
      :span,
      "",
      "data-carrier-product-metadata-for" => cp[:carrier_product_id],
      "data-carrier-product-metadata" => JSON.generate(metadata),
    )
  end
end
