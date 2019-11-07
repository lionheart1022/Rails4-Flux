class SessionsController < Devise::SessionsController
  helper_method :layout_config
  before_action :load_company_from_host

  protected

  def load_company_from_host
    domain = request.host
    @company = Company.find_company_with_domain(domain: domain)
  end

  def layout_config
    @_layout_config ||= begin
      config = @company ? LayoutConfig.new_from_company(@company) : LayoutConfig.new_generic

      config.body_class = "without_sidebar"
      config.root_path = new_user_session_path

      config
    end
  end
end
