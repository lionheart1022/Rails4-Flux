class CreateEconomicInvoiceExportTable < ActiveRecord::Migration
  def change
    create_table :economic_invoice_exports do |t|
      t.datetime :created_at, null: false
      t.references :parent, polymorphic: true, null: false
      t.datetime :finished_at
    end
  end
end
