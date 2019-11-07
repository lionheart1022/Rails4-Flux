class CleanUpTrackingData < ActiveRecord::Migration
  def change
    Tracking.where(status: 'collected_from_customer').each do |t|
      t.status = 'collected'
      t.save!
    end

    Tracking.where(status: 'received_at_origin_depot').each do |t|
      t.status = 'in_transit'
      t.save!
    end

    Tracking.where(status: 'received_at_tnt_location').each do |t|
      t.status = 'in_transit'
      t.save!
    end

    Tracking.where(status: 'out_for_delivery').each do |t|
      t.status = 'in_transit'
      t.save!
    end

    Tracking.where(description: 'Connection Delay. Recovery Actions Underway.').each do |t|
      t.status = 'in_transit'
      t.save!
    end

    Tracking.where(description: 'Shipment Received At Transit Point.').each do |t|
      t.status = 'in_transit'
      t.save!
    end

    Tracking.where(description: 'Shipment Delivered In Good Condition.').each do |t|
      t.status = 'delivered'
      t.save!
    end

    Tracking.where(description: 'Shipment Rerouted. Recovery Actions Underway.').each do |t|
      t.status = 'in_transit'
      t.save!
    end

    Tracking.where(description: 'Customer Not Home. Follow Up Actions Underway').each do |t|
      t.status = 'exception'
      t.save!
    end

    Tracking.where(description: 'Delay. Recovery Action Underway').each do |t|
      t.status = 'in_transit'
      t.save!
    end

    Tracking.where(description: 'Pre-arrival Customs Clearance In Progress').each do |t|
      t.status = 'in_transit'
      t.save!
    end

    Tracking.where(description: 'Shipment Arrived At Tnt Location').each do |t|
      t.status = 'in_transit'
      t.save!
    end

    Tracking.where(description: 'Customs Clearance In Progress.').each do |t|
      t.status = 'in_transit'
      t.save!
    end

    Tracking.where(description: 'Released By Customs').each do |t|
      t.status = 'in_transit'
      t.save!
    end

    Tracking.where(description: 'Contact With Receiver Required To Agree Delivery Date/time').each do |t|
      t.status = 'in_transit'
      t.save!
    end

    Tracking.where(description: 'Consignment Delivered To Residential').each do |t|
      t.status = 'delivered'
      t.save!
    end

    Tracking.where(description: 'Onforwarded For Delivery').each do |t|
      t.status = 'in_transit'
      t.save!
    end

    Tracking.where(description: 'Delay Due To Congestion En Route. Recovery Action Underway.').each do |t|
      t.status = 'in_transit'
      t.save!
    end

    Tracking.where(description: 'Delivery Date/time Slot Agreed With Receiver').each do |t|
      t.status = 'in_transit'
      t.save!
    end

    Tracking.where(description: 'Closed On Delivery Attempt. Follow Up Actions Underway').each do |t|
      t.status = 'exception'
      t.save!
    end

    Tracking.where(description: 'Shipment Delivered Damaged.').each do |t|
      t.status = 'delivered'
      t.save!
    end

  end
end
