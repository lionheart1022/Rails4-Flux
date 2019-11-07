class UserAccessResolver
  DEFAULT_HOSTS = DefaultHosts.list

  attr_reader :current_user
  attr_reader :host

  def initialize(current_user, host:)
    @current_user = current_user
    @host = host
  end

  def perform!
    matching_customer_accesses.load
    @single_company = matching_company
  end

  def access_to_single_customer?
    matching_customer_accesses.size == 1 && !@single_company && !current_user.is_executive?
  end

  def access_to_single_company?
    matching_customer_accesses.size == 0 && @single_company && !current_user.is_executive?
  end

  def current_customer_identifier
    matching_customer_accesses.size == 1 ? matching_customer_accesses[0].params_identifier : nil
  end

  private

  def matching_company
    all_companies.where(id: current_user.company_id).first unless current_user.is_customer?
  end

  def matching_customer_accesses
    @matching_customer_accesses ||=
      current_user
      .user_customer_accesses
      .active
      .where(company_id: all_companies.select(:id))
  end

  def all_companies
    if DEFAULT_HOSTS.include?(host)
      Company.all
    else
      Company.where(domain: host)
    end
  end
end
