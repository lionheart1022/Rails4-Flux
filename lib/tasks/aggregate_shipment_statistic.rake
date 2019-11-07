namespace :aggregate_shipment_statistic do
  desc "Refresh aggregate statistic that are marked for refreshing"
  task refresh: :environment do
    AggregateShipmentStatistic.process_changed_shipments
    RefreshStatsJob.perform_later
  end
end
