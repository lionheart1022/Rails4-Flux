class AddCompanyCustomerToAggregatedShipmentStats < ActiveRecord::Migration
  def change
    add_reference :aggregate_shipment_statistics, :company_customer
  end
end
