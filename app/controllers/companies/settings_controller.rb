class Companies::SettingsController < CompaniesController
  def show
  end

  private

  def set_current_nav
    @current_nav = "company_settings"
  end
end
