class CarrierProductsMigrateDataTypeField < ActiveRecord::Migration
  def up
    CarrierProduct.all.each do |carrier_product|
      carrier_product.type = 'CarrierProduct'
      carrier_product.save!
    end
  end
end
