class EconomicInvoiceRequestJob < ActiveJob::Base
  queue_as :reports

  def perform(report_id, company_id)
    company = Company.find(company_id)
    report = Report.where(company_id: company_id).find(report_id)
    economic_access = EconomicAccess.active.find_by!(owner: company)

    EconomicInvoiceRecord.enqueued.not_sent.where(parent: report).each do |economic_invoice|
      http_request = EconomicInvoiceHTTPRequest.new(
        agreement_grant_token: economic_access.agreement_grant_token,
        external_accounting_number: economic_invoice.external_accounting_number,
        custom_reference: report.report_id.to_s,
        lines: economic_invoice.ordered_lines.pluck(:payload),
      )

      begin
        http_request.perform!
      rescue EconomicInvoiceHTTPRequest::InvoiceTemplateNotFound
        economic_invoice.update!(
          http_request_succeeded: false,
          http_request_failed: true,
        )
      rescue EconomicInvoiceHTTPRequest::InvoiceTemplateNotFoundAsJSON => e
        ExceptionMonitoring.report(e, context: { report_id: report_id, economic_invoice_id: economic_invoice.id, parse_error: e.parse_error.to_s, response_body: e.response_body, external_accounting_number: e.external_accounting_number })

        economic_invoice.update!(
          http_request_succeeded: false,
          http_request_failed: true,
        )
      rescue => e
        ExceptionMonitoring.report(e, context: { report_id: report_id, economic_invoice_id: economic_invoice.id })

        economic_invoice.update!(
          http_request_succeeded: false,
          http_request_failed: true,
        )
      else
        economic_invoice.update!(
          http_request_sent_at: Time.now,
          http_request_succeeded: true,
        )
      end
    end
  end
end
