module CFExec
  class UserNotificationsController < ExecController
    def destroy
      @user = User.find(params[:user_id])

      @user.email_settings.disable_all_notifications! if @user.email_settings

      redirect_to exec_user_path(@user)
    end
  end
end
