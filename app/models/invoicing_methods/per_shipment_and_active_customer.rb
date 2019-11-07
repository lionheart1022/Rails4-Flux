module InvoicingMethods
  class PerShipmentAndActiveCustomer < Base
    def shipment_count_in_period(from, to)
      Shipment
        .find_company_shipments(company_id: company_id)
        .where("created_at >= ? and created_at <= ?", from, to)
        .count
    end

    def customer_count_in_period(_from, to)
      count_active_customers_with_shipments_created_after(to - 3.months) + count_carrier_product_customers_created_before(to)
    end

    private

    def count_active_customers_with_shipments_created_after(after_date, shipment_threshold: 0)
      Customer
        .find_company_customers(company_id: company_id)
        .select("customers.*, COUNT(shipments.id) AS no_of_shipments")
        .joins(:shipments)
        .where("shipments.created_at >= ?", after_date)
        .group("customers.id")
        .select { |customer| customer.no_of_shipments > shipment_threshold }
        .count
    end

    def count_carrier_product_customers_created_before(before_date)
      Company
        .find_carrier_product_customers(company_id: company_id)
        .where("companies.created_at <= ?", before_date)
        .count
    end
  end
end
