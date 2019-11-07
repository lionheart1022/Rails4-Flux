class CreateCarrierProductAutobookRequests < ActiveRecord::Migration
  def change
    create_table :carrier_product_autobook_requests do |t|
      t.belongs_to  :shipment
      t.belongs_to  :company
      t.belongs_to  :customer
      t.string      :uuid
      t.string      :state
      t.text        :info
      t.string      :type
      t.timestamps
    end
  end
end
