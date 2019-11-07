class ProcessInvoiceValidationJob < ActiveJob::Base
  queue_as :imports

  after_enqueue do |job|
    InvoiceValidation.find(job.arguments.first).update!(status: InvoiceValidation::States::PROCESSING_FILE)
  end

  def perform(id)
    invoice_validation = InvoiceValidation.find(id)

    file = Tempfile.new(["invoice_validation", ".xlsx"])
    file.binmode

    begin
      invoice_validation.read_file do |chunk|
        file.write(chunk)
      end

      file.rewind

      workbook = Creek::Book.new(file.path)
      sheet = workbook.sheets[0]

      body_rows = sheet.rows.drop(1)

      body_rows.each do |row|
        invoice_validation.invoice_validation_row_records.create(field_data: row) unless row.empty?
      end
    ensure
      file.close
      file.unlink
    end
    invoice_validation.write_error_rows
    invoice_validation.update!(status: InvoiceValidation::States::PROCESSED_FILE)
  rescue => e
    invoice_validation.update!(status: InvoiceValidation::States::FAILED)
    ExceptionMonitoring.report_exception!(e, context: { invoice_validation_id: invoice_validation.id }, raise_in_environments: %w{development})
  end
end
