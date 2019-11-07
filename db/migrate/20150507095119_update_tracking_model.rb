class UpdateTrackingModel < ActiveRecord::Migration
  def up

    add_column :trackings, :event_date, :date
    add_column :trackings, :event_time, :time
    add_column :trackings, :expected_delivery_date, :date
    add_column :trackings, :expected_delivery_time, :time
    add_column :trackings, :signatory, :string
    add_column :trackings, :event_country, :string
    add_column :trackings, :event_city, :string
    add_column :trackings, :event_zip_code, :string
    add_column :trackings, :depot_name, :string

    Tracking.all.each do |tracking|
      tracking.event_date = Date.parse(tracking.date.to_s)
      tracking.save!
    end

    remove_column :trackings, :date
  end

  def down
    add_column :trackings, :date, :date

    Tracking.all.each do |tracking|
      tracking.date = Date.parse(tracking.event_date.to_s)
      tracking.save!
    end

    remove_column :trackings, :event_date
    remove_column :trackings, :event_time
    remove_column :trackings, :expected_delivery_date
    remove_column :trackings, :expected_delivery_time
    remove_column :trackings, :signatory
    remove_column :trackings, :event_country, :string
    remove_column :trackings, :event_city, :string
    remove_column :trackings, :event_zip_code, :string
    remove_column :trackings, :depot_name

  end

end
