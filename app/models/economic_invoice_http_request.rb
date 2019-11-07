class EconomicInvoiceHTTPRequest
  BASE_URI = "https://restapi.e-conomic.com"

  class BaseError < StandardError; end
  class InvoiceTemplateNotFound < BaseError; end
  class InvoiceTemplateNotFoundAsJSON < BaseError
    attr_reader :parse_error
    attr_reader :response_body
    attr_reader :external_accounting_number

    def initialize(msg, parse_error: nil, response_body: nil, external_accounting_number: nil)
      super(msg)

      @parse_error = parse_error
      @response_body = response_body
      @external_accounting_number = external_accounting_number
    end
  end

  attr_accessor :secret_token
  attr_accessor :agreement_grant_token
  attr_accessor :external_accounting_number
  attr_accessor :custom_reference
  attr_accessor :lines

  def initialize(params = {})
    self.secret_token = ENV["ECONOMIC_APP_SECRET_TOKEN"]
    self.lines = []

    params.each do |attr, value|
      self.public_send("#{attr}=", value)
    end
  end

  def perform!
    raise ArgumentError, "secret_token missing" if secret_token.blank?
    raise ArgumentError, "agreement_grant_token missing" if agreement_grant_token.blank?
    raise ArgumentError, "external_accounting_number missing" if external_accounting_number.blank?

    invoice_template_response = fetch_invoice_template

    case invoice_template_response
    when Net::HTTPNotFound
      begin
        parsed_invoice_template_response = JSON.parse(invoice_template_response.body)
      rescue JSON::ParserError => e
        raise InvoiceTemplateNotFoundAsJSON.new("Invoice template 404 response is not JSON as expected", parse_error: e, response_body: invoice_template_response.body, external_accounting_number: external_accounting_number)
      else
        raise InvoiceTemplateNotFound, parsed_invoice_template_response.fetch("message")
      end
    else
      # Raise a HTTP error if the response is not 2xx (success).
      invoice_template_response.value
    end

    @invoice_template = JSON.parse(invoice_template_response.body)

    draft_invoice_response = create_draft_invoice
    draft_invoice_response.value
    draft_invoice_response
  end

  private

  def draft_invoice_request_json
    @invoice_template.merge(
      "lines" => lines,
      "references" => {
        "other" => custom_reference,
      },
    )
  end

  def create_draft_invoice
    uri = URI("#{BASE_URI}/invoices/drafts")
    headers = {
      "Content-Type" => "application/json",
      "X-AppSecretToken" => secret_token,
      "X-AgreementGrantToken" => agreement_grant_token
    }

    body = JSON.generate(draft_invoice_request_json)

    Rails.logger.tagged("EconomicInvoiceHTTPRequest", "CreateDraftInvoiceRequest.Body") do
      Rails.logger.info body
    end

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      res = http.request_post(uri.path, body, headers)

      Rails.logger.tagged("EconomicInvoiceHTTPRequest", "CreateDraftInvoiceResponse.Body") do
        Rails.logger.info res.body
      end

      return res
    end
  end

  def fetch_invoice_template
    uri = URI("#{BASE_URI}/customers/#{URI.escape(external_accounting_number)}/templates/invoice")
    headers = {
      "X-AppSecretToken" => secret_token,
      "X-AgreementGrantToken" => agreement_grant_token
    }

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      res = http.request_get(uri.path, headers)

      Rails.logger.tagged("EconomicInvoiceHTTPRequest", "FetchInvoiceTemplateResponse.Body") do
        Rails.logger.info res.body
      end

      return res
    end
  end
end
