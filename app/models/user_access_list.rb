class UserAccessList
  DEFAULT_HOSTS = DefaultHosts.list

  attr_reader :current_user
  attr_reader :host

  def initialize(current_user, host:)
    @current_user = current_user
    @host = host
  end

  def customer_accesses
    current_user
      .user_customer_accesses
      .active
      .where(company_id: all_companies.select(:id))
      .includes(:company, :customer)
  end

  def company
    all_companies.where(id: current_user.company_id).first unless current_user.is_customer?
  end

  private

  def all_companies
    if DEFAULT_HOSTS.include?(host)
      Company.all
    else
      Company.where(domain: host)
    end
  end
end
