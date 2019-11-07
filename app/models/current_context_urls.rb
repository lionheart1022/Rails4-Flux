class CurrentContextUrls
  include Rails.application.routes.url_helpers

  attr_reader :company, :customer

  def initialize(company:, customer: nil)
    @company = company
    @customer = customer
  end

  def company_host
    if defined?(@company_host)
      @company_host
    else
      @company_host = company.domain.presence || Rails.application.config.action_mailer.default_url_options[:host]
    end
  end

  def default_url_options
    base_options = {
      host: company_host,
      protocol: Rails.env.production? ? "https" : ENV.fetch("DEFAULT_URL_PROTOCOL", "http"),
    }

    base_options[:current_customer_identifier] = customer.id if customer

    base_options
  end
end
