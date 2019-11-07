module CustomLabelVariants
  class SamskipViewModel < SimpleDelegator
    def logo_url
      shipment.product_responsible && shipment.product_responsible.asset_logo && shipment.product_responsible.asset_logo.attachment.url
    end

    def sender
      shipment.sender
    end

    def recipient
      shipment.recipient
    end

    def company_address
      "Jernholment 48K"
    end

    def company_postal_code_and_city
      "2650 Hvidovre"
    end

    def company_phone_number
      "3927 1213"
    end

    def company_fax_number
      "3927 1210"
    end

    def company_email
      "cph.distribution@samskip.com"
    end

    def volume_weight_unit
      if shipment.package_dimensions.loading_meter?
        "ldm"
      end
    end

    def aggregated_package_dimensions
      shipment.package_dimensions.aggregate
    end

    def shipment_id
      shipment.unique_shipment_id
    end

    def date
      shipment.shipping_date
    end

    def reference
      shipment.reference
    end

    def main_view
      "components/custom_label_variants/samskip"
    end

    private

    def shipment
      __getobj__
    end
  end
end
