class AddEconomicInvoicesStateToReports < ActiveRecord::Migration
  def change
    add_column :reports, :economic_invoices_state, :string
  end
end
