namespace :shipments do
  desc "Shipment tracking"
  task track: :environment do
    ShipmentTrackingManager.track
  end
end
