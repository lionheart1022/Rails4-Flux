class AddPricingTypeToCarrierProductPrices < ActiveRecord::Migration

  def up
    add_column :carrier_products, :product_type, :string
    add_product_type_to_existing_top_level_products
  end

  def down
    remove_column :carrier_products, :product_type
  end

  private

    def add_product_type_to_existing_top_level_products
      CarrierProduct.find_all_top_level_ancestors.each do |cp|
        cp.product_type = CarrierProduct::ProductTypes::COURIER_EXPRESS
        cp.save!
      end
    end

end
