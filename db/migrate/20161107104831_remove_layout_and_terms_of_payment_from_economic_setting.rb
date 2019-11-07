class RemoveLayoutAndTermsOfPaymentFromEconomicSetting < ActiveRecord::Migration
  def change
    remove_column :economic_settings, :payment_terms, :string
    remove_column :economic_settings, :layout_number, :String
  end
end
