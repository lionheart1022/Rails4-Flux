module UPSBillingXMLFile
  class << self
    def parse_xml(xml_as_string)
      doc = Nokogiri.XML(xml_as_string)
      doc.remove_namespaces!
      parse(doc)
    end

    def parse(doc)
      parse_result = {}

      doc.xpath("//InvoiceDetails/Invoice").each do |invoice|
        account_number = invoice.at_xpath("Account/AccountNumber")&.text

        invoice.xpath('./TransactionDetails/Shipment').each do |shipment|
          lead_shipment_number = shipment.at_xpath("./LeadShipmentNumber").text

          # If the same shipment appears multiple times it will not be handled.
          if parse_result.key?(lead_shipment_number)
            Rails.logger.warn "UPSBillingXMLFile:duplicate_shipments_are_not_handled lead_shipment_number=#{lead_shipment_number}"
            parse_result.delete(lead_shipment_number)
            next
          end

          shipment_attrs = {
            account_number: account_number,
            lead_shipment_number: lead_shipment_number,
            shipment_reference_1: shipment.at_xpath("./ShipmentReferences/Reference[1]/ReferenceNumber")&.text,
            shipment_reference_2: shipment.at_xpath("./ShipmentReferences/Reference[2]/ReferenceNumber")&.text,
            packages: {},
          }

          parse_result[lead_shipment_number] = shipment_attrs

          shipment.xpath("./Package").each_with_object(shipment_attrs[:packages]) do |package, shipment_packages|
            pkg_tracking_number = package.at_xpath("./TrackingNumber")&.text

            if pkg_tracking_number.nil?
              Rails.logger.warn "UPSBillingXMLFile:no_pkg_tracking_number lead_shipment_number=#{lead_shipment_number}"
              next
            end

            pkg_quantity = package.at_xpath("./PackageQuantity/ActualQuantity/Quantity")&.text&.strip
            pkg_billed_weight_type = package.at_xpath("./PackageWeight/BilledWeightType")&.text&.strip

            # Only the 29+30 billed weight types seem to have actual weight data, for the other types the weights are 0.
            next unless %w(29 30).include?(pkg_billed_weight_type)

            # For now only 1-package shipments are considered
            next unless pkg_quantity == "1"

            # This conditional is related to the 1-package shipment limitation.
            if shipment_packages.length > 0
              Rails.logger.warn "UPSBillingXMLFile:only_expected_1_package lead_shipment_number=#{lead_shipment_number} pkg_tracking_number=#{pkg_tracking_number}"
              shipment_packages.clear
              next
            end

            shipment_packages[pkg_tracking_number] = {
              pkg_tracking_number: pkg_tracking_number,
              pkg_container: package.at_xpath("./ContainerType")&.text,
              pkg_quantity: pkg_quantity,
              pkg_billed_weight_type: pkg_billed_weight_type,
              pkg_actual_weight: package.at_xpath("./PackageWeight/ActualWeight/Weight")&.text,
              pkg_actual_weight_unit: package.at_xpath("./PackageWeight/ActualWeight/UnitOfMeasure")&.text,
              pkg_billed_weight: package.at_xpath("./PackageWeight/BilledWeight/Weight")&.text,
              pkg_billed_weight_unit: package.at_xpath("./PackageWeight/BilledWeight/UnitOfMeasure")&.text,
              pkg_surcharges: [],
            }

            package.xpath("./ChargeDetails/Charge").each_with_object(shipment_packages[pkg_tracking_number][:pkg_surcharges]) do |charge, pkg_surcharges|
              charge_identifier = charge_to_identifier(charge)
              pkg_surcharges << charge_identifier if charge_identifier
            end
          end
        end
      end

      parse_result
    end

    def charge_to_identifier(charge)
      classification_code = charge.at_xpath("./ClassificationCode").text.strip
      description_code = charge.at_xpath("./ChargeInformation/DescriptionCode").text.strip

      return if %w(FRT TAX FSC).include?(classification_code)

      case [classification_code, description_code]
      when ["ACC", "RES"]
        [:ok, :residential]
      when ["ACC", "HIS"]
        [:ok, :remote_area]
      when ["ACC", "ESD"]
        [:ok, :extended_area_delivery]
      when ["ACC", "AHC"]
        [:ok, :additional_handling]
      else
        [:unknown, "#{classification_code}|#{description_code}"]
      end
    end
  end
end
