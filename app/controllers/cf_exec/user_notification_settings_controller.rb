module CFExec
  class UserNotificationSettingsController < ExecController
    def create
      @user = User.find(params[:user_id])

      @user.email_settings.enable_notification_setting!(params[:key]) if @user.email_settings

      respond_to do |format|
        format.html { redirect_to exec_user_path(@user) }
      end
    end

    def destroy
      @user = User.find(params[:user_id])

      @user.email_settings.disable_notification_setting!(params[:id]) if @user.email_settings

      respond_to do |format|
        format.html { redirect_to exec_user_path(@user) }
      end
    end
  end
end
