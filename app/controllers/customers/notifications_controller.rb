class Customers::NotificationsController < CustomersController
  before_action :set_email_settings

  def show
    render :edit
  end

  def update
    @email_settings.assign_attributes(email_settings_params)

    if @email_settings.save
      redirect_to customers_notification_path
    else
      render :edit
    end
  end

  private

  def set_email_settings
    @email_settings = EmailSettings.find_or_initialize_by(user_id: current_user.id)
  end

  def email_settings_params
    params.fetch(:email_settings, {}).permit(*EmailSettings::FLAG_ATTRIBUTES_FOR_CUSTOMER_USER)
  end

  def set_current_nav
    @current_nav = "notifications"
  end
end
