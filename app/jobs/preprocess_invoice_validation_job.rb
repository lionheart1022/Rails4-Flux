class PreprocessInvoiceValidationJob < ActiveJob::Base
  queue_as :imports

  after_enqueue do |job|
    InvoiceValidation.find(job.arguments.first).update!(status: InvoiceValidation::States::PREPROCESSING_FILE)
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

      header_row = sheet.rows.first
      body_rows = sheet.rows

      valid = false
      body_rows.map do |row|
        valid = true if row != {}
      end

      if valid == false
        invoice_validation.update!(status: InvoiceValidation::States::EMPTY_FILE)
        return
      elsif header_row == {}
        invoice_validation.update!(status: InvoiceValidation::States::ERROR_HEADER)
        return
      else
        invoice_validation.update!(header_row: header_row)
        invoice_validation.update!(status: InvoiceValidation::States::PREPROCESSED_FILE)
      end
    ensure
      file.close
      file.unlink
    end
  rescue => e
    invoice_validation.update!(status: InvoiceValidation::States::FAILED)
    ExceptionMonitoring.report_exception!(e, context: { invoice_validation_id: invoice_validation.id })
  end
end
