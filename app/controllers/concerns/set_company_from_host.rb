module SetCompanyFromHost
  extend ActiveSupport::Concern

  included do
    before_action :set_company_from_host
  end

  private

  def set_company_from_host
    @company = Company.find_company_with_domain(domain: request.host)
  end
end
