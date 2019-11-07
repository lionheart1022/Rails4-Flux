class AddDetailedPricingFlagOnReports < ActiveRecord::Migration
  def change
    add_column :reports, :with_detailed_pricing, :boolean, default: false
  end
end
