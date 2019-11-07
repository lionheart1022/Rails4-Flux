module InvoicingMethods
  class FixedPrice < Base
    def can_destroy_via_ui?
      true
    end

    def shipment_count_in_period(from, to)
      Shipment
        .find_company_shipments(company_id: company_id)
        .where("created_at >= ? and created_at <= ?", from, to)
        .count
    end

    def customer_count_in_period(_from, to)
      count_customers_created_before(to) + count_carrier_product_customers_created_before(to)
    end

    private

    def count_customers_created_before(before_date)
      Customer
        .find_company_customers(company_id: company_id)
        .where("created_at <= ?", before_date)
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
