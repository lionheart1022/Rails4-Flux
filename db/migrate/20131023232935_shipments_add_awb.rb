class ShipmentsAddAwb < ActiveRecord::Migration
  def change
    add_column(:shipments, :awb, :string)
  end
end
