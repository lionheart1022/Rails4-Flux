module InvoicingMethods
  class PerShipment < Base
    def shipment_count_in_period(from, to)
      Shipment
        .find_company_shipments(company_id: company_id)
        .where("created_at >= ? and created_at <= ?", from, to)
        .count
    end
  end
end
