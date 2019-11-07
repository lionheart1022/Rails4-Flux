class CustomerImportPerformJob < ActiveJob::Base
  queue_as :imports

  after_enqueue do |job|
    CustomerImport.find(job.arguments.first).touch(:perform_enqueued_at)
  end

  def perform(customer_import_id)
    customer_import = CustomerImport.find(customer_import_id)
    return if customer_import.perform_completed_at?

    begin
      customer_rows_as_records = customer_import.rows.valid_for_creating_customer
      customer_rows = customer_rows_as_records.map(&:as_plain_row)
      customer_rows.reject!(&:invalid?)

      bulk_create = CustomerBulkCreate.new(company: customer_import.company, customer_rows: customer_rows)
      bulk_create.send_invitation_email = customer_import.send_invitation_email
      bulk_create.perform!

      customer_import.touch(:perform_completed_at)
    rescue => e
      customer_import.update!(status: CustomerImport::States::FAILED)
      ExceptionMonitoring.report_exception!(e, context: { customer_import_id: customer_import_id })
    end
  end
end
