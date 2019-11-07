module InvoicingMethods
  class PerActiveCustomerInPeriod < Base
    def count_in_period(_from, _to)
      nil
    end

    def detailed_customer_stats_in_period(from, to)
      customer_stats = []

      customers_with_shipment_count_in_period(from, to).each do |customer|
        customer_stats << CustomerStat.new(customer.name, customer.no_of_shipments)
      end

      # TODO: We should probably also include the carrier product customers right here
      # I haven't done this yet because it is not trivial to look up.

      customer_stats
    end

    private

    def customers_with_shipment_count_in_period(from, to)
      Customer
        .find_company_customers(company_id: company_id)
        .select("customers.*, COUNT(shipments.id) AS no_of_shipments")
        .joins(:shipments)
        .where("shipments.created_at >= ?", from)
        .where("shipments.created_at <= ?", to)
        .group("customers.id")
        .order("no_of_shipments DESC")
    end

    CustomerStat = Struct.new(:customer_name, :shipment_count)
  end
end
