require "csv"

class InvoicingReport
  attr_reader :from, :to

  def initialize(from:, to:)
    @from = from
    @to = to
  end

  def produce_csv
    CSV.generate(col_sep: ";") do |csv|
      csv << ["REPORT"]
      csv << ["From #{from.strftime("%-d %B %Y")} to #{to.strftime("%-d %B %Y")}"]

      csv << []
      csv << ["### Fixed price"]
      csv << ["Company", "Shipment count", "Customer count"]
      InvoicingMethods::FixedPrice.all.order(:company_id).each do |invoicing|
        csv << ["#{invoicing.company.name} (id=#{invoicing.company.id})", invoicing.shipment_count_in_period(from, to), invoicing.customer_count_in_period(from, to)]
      end

      csv << []
      csv << ["### Shipments"]
      csv << ["Company", "Shipment count"]
      InvoicingMethods::PerShipment.all.order(:company_id).each do |invoicing|
        csv << ["#{invoicing.company.name} (id=#{invoicing.company.id})", invoicing.shipment_count_in_period(from, to)]
      end

      csv << []
      csv << ["### Shipments and active customers"]
      csv << ["Company", "Shipment count", "Active customer count"]
      InvoicingMethods::PerShipmentAndActiveCustomer.all.order(:company_id).each do |invoicing|
        csv << ["#{invoicing.company.name} (id=#{invoicing.company.id})", invoicing.shipment_count_in_period(from, to), invoicing.customer_count_in_period(from, to)]
      end

      csv << []
      csv << ["### Customers (active model)"]
      csv << ["Company", "Active customer count"]
      InvoicingMethods::PerActiveCustomer.all.order(:company_id).each do |invoicing|
        csv << ["#{invoicing.company.name} (id=#{invoicing.company.id})", invoicing.count_in_period(from, to)]
      end

      csv << []
      csv << ["### Customers (active model, shipment and ferry booking)"]
      csv << ["Company", "Total active customer count", "Active non-ferry booking customer count", "Active ferry booking customer count", "Active shipment customer count"]
      InvoicingMethods::PerActiveShipmentCustomerAndFerryBookingCustomer.all.order(:company_id).each do |invoicing|
        csv << ["#{invoicing.company.name} (id=#{invoicing.company.id})", invoicing.active_all_shipment_customer_count_in_period(from, to), invoicing.active_regular_shipment_customer_count_in_period(from, to), invoicing.active_ferry_booking_customer_count_in_period(from, to), invoicing.active_regular_shipment_and_ferry_booking_customer_count_in_period(from, to)]
      end

      csv << []
      csv << ["### Customers"]
      csv << ["Company", "Customer count"]
      InvoicingMethods::PerCustomer.all.order(:company_id).each do |invoicing|
        csv << ["#{invoicing.company.name} (id=#{invoicing.company.id})", invoicing.count_in_period(from, to)]
      end

      csv << []
      csv << ["-" * 80]

      InvoicingMethods::PerActiveCustomerInPeriod.all.order(:company_id).each do |invoicing|
        csv << []
        csv << ["### Company: #{invoicing.company.name}"]
        csv << ["Customer", "Shipment count"]

        invoicing.detailed_customer_stats_in_period(from, to).each do |customer_stat|
          csv << [customer_stat.customer_name, customer_stat.shipment_count]
        end
      end
    end
  end
end
