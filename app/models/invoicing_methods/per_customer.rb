module InvoicingMethods
  class PerCustomer < Base
    def count_in_period(_from, to)
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
