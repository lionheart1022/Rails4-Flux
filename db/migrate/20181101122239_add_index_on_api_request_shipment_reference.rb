class AddIndexOnAPIRequestShipmentReference < ActiveRecord::Migration
  def change
    add_index :api_requests, :shipment_id
  end
end
