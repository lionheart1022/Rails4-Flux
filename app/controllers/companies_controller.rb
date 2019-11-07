class CompaniesController < AdminController
  before_action :set_body_class_for_company
  before_action :ensure_user_is_company_user
  helper_method :navigation
  helper_method :layout_config

  private

  def ensure_user_is_company_user
    if current_context.is_customer?
      flash[:notice] = "Only company users are allowed to do that."
      redirect_to :admin_root
    end
  end

  def navigation
    @_navigation_view_model ||= AdminNavigation.for_company(current_company)
  end

  def layout_config
    @_layout_config ||= begin
      config = LayoutConfig.new_from_company(current_company)

      config.body_class = @body_class
      config.root_path = admin_root_path

      config
    end
  end

  def set_body_class_for_company
    set_body_class("companies")
  end
end
