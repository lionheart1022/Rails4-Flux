class CustomerImportParseJob < ActiveJob::Base
  queue_as :imports

  COLUMN_NAMES = [
    :created_at,
    :updated_at,
    :customer_import_id,
    :field_data,
  ]

  after_enqueue do |job|
    CustomerImport.find(job.arguments.first).touch(:parsing_enqueued_at)
  end

  def perform(customer_import_id)
    customer_import = CustomerImport.find(customer_import_id)
    return if customer_import.parsing_completed_at?

    now = nil

    file = Tempfile.new(["customer_import", ".xlsx"])
    file.binmode

    begin
      customer_import.read_file do |chunk|
        file.write(chunk)
      end

      file.rewind

      parser = CustomerImportExcelParser.new(file: file, company: customer_import.company)
      parser.perform!

      now ||= Time.zone.now

      rows_attributes = parser.result.map do |row|
        {
          created_at: now,
          updated_at: now,
          customer_import_id: customer_import.id,
          field_data: row.attributes,
        }
      end

      customer_import.transaction do
        bulk_insertion = BulkInsertion.new(rows_attributes, column_names: COLUMN_NAMES, model_class: ::CustomerImportRowRecord)
        bulk_insertion.perform!

        customer_import.touch(:parsing_completed_at)
      end
    rescue => e
      customer_import.update!(status: CustomerImport::States::FAILED)
      ExceptionMonitoring.report_exception!(e, context: { customer_import_id: customer_import_id })
    ensure
      file.close
      file.unlink
    end
  end
end
