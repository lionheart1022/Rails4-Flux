class CreateIndexForHandledAtOnAggregateShipmentStatisticChanges < ActiveRecord::Migration
  def change
    add_index :aggregate_shipment_statistic_changes, :handled_at
  end
end
