class AccountSelectorController < AdminController
  helper_method :layout_config
  before_action :load_company_from_host

  def index
    @user_access_list = UserAccessList.new(current_user, host: request.host)
  end

  private

  def layout_config
    @_layout_config ||= begin
      config = @company ? LayoutConfig.new_from_company(@company) : LayoutConfig.new_generic

      config.body_class = "without_sidebar"
      config.root_path = admin_root_path

      config
    end
  end

  def load_company_from_host
    @company = Company.find_company_with_domain(domain: request.host)
  end

  def user_access_symbol
    nil # Override, so we don't show the "Switch account" link
  end
end
