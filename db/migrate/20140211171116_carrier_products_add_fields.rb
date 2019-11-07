class CarrierProductsAddFields < ActiveRecord::Migration
  def up
    add_column(:carrier_products, :custom_volume_weight_enabled, :boolean)
    add_column(:carrier_products, :volume_weight_factor, :integer)
    add_column(:carrier_products, :track_trace_method, :string)

    CarrierProduct.all.each do |cp|
      if cp.supports_track_and_trace? == false
        cp.track_trace_method = CarrierProduct::TrackTraceMethods::NONE
        cp.save!
      end
    end
  end

  def down
    remove_column(:carrier_products, :custom_volume_weight_enabled)
    remove_column(:carrier_products, :volume_weight_factor)
    remove_column(:carrier_products, :track_trace_method)
  end
end
