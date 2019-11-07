class UnlocksController < Devise::UnlocksController
  before_action :load_company_from_host

  protected

  def load_company_from_host
    domain = request.host
    @company = Company.find_company_with_domain(domain: domain)
  end
end