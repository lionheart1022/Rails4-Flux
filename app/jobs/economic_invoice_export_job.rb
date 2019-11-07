class EconomicInvoiceExportJob < ActiveJob::Base
  queue_as :reports

  def perform(export_id)
    export = EconomicInvoiceExportRecord.find(export_id)
    export.generate_and_create_invoices!
  end
end
