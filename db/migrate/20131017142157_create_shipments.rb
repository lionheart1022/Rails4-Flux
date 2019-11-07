class CreateShipments < ActiveRecord::Migration
  def change
    create_table :shipments do |t|
      t.belongs_to  :company
      t.belongs_to  :user
      t.belongs_to  :shipping_product
      t.date        :shipping_date
      t.boolean     :dutiable
      t.decimal     :customs_amount, :precision => 8, :scale => 2
      t.string      :customs_currency
      t.string      :customs_code
      t.integer     :number_of_packages
      t.text        :package_dimensions
      t.text        :description
      t.string      :state
      t.timestamps
    end
  end
end
