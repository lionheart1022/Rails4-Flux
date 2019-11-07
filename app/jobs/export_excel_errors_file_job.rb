class ExportExcelErrorsFileJob < ActiveJob::Base
  queue_as :imports

  after_enqueue do |job|
    InvoiceValidation.find(job.arguments.first).update!(status: InvoiceValidation::States::EXPORTING_EXCEL_ERRORS)
  end

  def perform(id)
    @invoice_validation = InvoiceValidation.find(id)

    return if @invoice_validation.status == InvoiceValidation::States::EXPORTED_EXCEL_ERRORS
    
    @invoice_validation.generate_excel_errors_report_now!
    @invoice_validation.update!(status: InvoiceValidation::States::EXPORTED_EXCEL_ERRORS)
  rescue
    @invoice_validation.update!(status: InvoiceValidation::States::FAILED)
    ExceptionMonitoring.report_exception!(e, context: { invoice_validation_id: id })
  end
end
