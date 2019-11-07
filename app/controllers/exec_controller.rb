class ExecController < ActionController::Base
  include UserAccessResolving

  before_action :authenticate_user!
  before_action :ensure_user_is_executive!
  helper_method :cached_active_nav
  helper_method :layout_config

  private

  def cached_active_nav
    if defined?(@_active_nav)
      @_active_nav
    else
      @_active_nav = active_nav
    end
  end

  def active_nav
  end

  def layout_config
    @_layout_config ||= LayoutConfig.new.tap do |config|
      config.title = "EXEC"
      config.primary_brand_color = "#27565C"
      config.root_path = exec_path
    end
  end

  def ensure_user_is_executive!
    if !current_user.is_executive?
      render file: Rails.public_path.join("404.html"), layout: false, status: :not_found
    end
  end
end
