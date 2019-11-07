module InvoicingMethods
  class PerActiveShipmentCustomerAndFerryBookingCustomer < Base
    def active_all_shipment_customer_count_in_period(_from, to)
      customer_ids = customer_id_of_active_customers_with_all_shipments_created_in_period(from: to - 3.months, to: to)

      customer_ids.count + count_carrier_product_customers_created_before(to)
    end

    def active_regular_shipment_customer_count_in_period(_from, to)
      customer_ids  = customer_id_of_active_customers_with_regular_shipments_created_in_period(from: to - 3.months, to: to)
      customer_ids -= customer_id_of_active_customers_with_ferry_booking_shipments_created_in_period(from: to - 3.months, to: to)

      customer_ids.count + count_carrier_product_customers_created_before(to)
    end

    def active_ferry_booking_customer_count_in_period(_from, to)
      customer_ids  = customer_id_of_active_customers_with_ferry_booking_shipments_created_in_period(from: to - 3.months, to: to)
      customer_ids -= customer_id_of_active_customers_with_regular_shipments_created_in_period(from: to - 3.months, to: to)

      customer_ids.count
    end

    def active_regular_shipment_and_ferry_booking_customer_count_in_period(_from, to)
      customer_ids  = customer_id_of_active_customers_with_regular_shipments_created_in_period(from: to - 3.months, to: to)
      customer_ids &= customer_id_of_active_customers_with_ferry_booking_shipments_created_in_period(from: to - 3.months, to: to)

      customer_ids.count
    end

    private

    def customer_id_of_active_customers_with_all_shipments_created_in_period(from:, to:, shipment_threshold: 0)
      Customer
        .find_company_customers(company_id: company_id)
        .select("customers.*, COUNT(shipments.id) AS no_of_shipments")
        .joins(:shipments)
        .where("shipments.created_at >= ?", from)
        .where("shipments.created_at <= ?", to)
        .group("customers.id")
        .select { |customer| customer.no_of_shipments > shipment_threshold }
        .map(&:id)
    end

    def customer_id_of_active_customers_with_regular_shipments_created_in_period(from:, to:, shipment_threshold: 0)
      Customer
        .find_company_customers(company_id: company_id)
        .select("customers.*, COUNT(shipments.id) AS no_of_shipments")
        .joins(:shipments)
        .where(shipments: { ferry_booking_shipment: false })
        .where("shipments.created_at >= ?", from)
        .where("shipments.created_at <= ?", to)
        .group("customers.id")
        .select { |customer| customer.no_of_shipments > shipment_threshold }
        .map(&:id)
    end

    def customer_id_of_active_customers_with_ferry_booking_shipments_created_in_period(from:, to:, shipment_threshold: 0)
      Customer
        .find_company_customers(company_id: company_id)
        .select("customers.*, COUNT(shipments.id) AS no_of_shipments")
        .joins(:shipments)
        .where(shipments: { ferry_booking_shipment: true })
        .where("shipments.created_at >= ?", from)
        .where("shipments.created_at <= ?", to)
        .group("customers.id")
        .select { |customer| customer.no_of_shipments > shipment_threshold }
        .map(&:id)
    end

    def count_carrier_product_customers_created_before(before_date)
      Company
        .find_carrier_product_customers(company_id: company_id)
        .where("companies.created_at <= ?", before_date)
        .count
    end
  end
end
