class AddVatFlagToEconomicInvoiceLine < ActiveRecord::Migration
  def change
    add_column :economic_invoice_lines, :includes_vat, :boolean
  end
end
