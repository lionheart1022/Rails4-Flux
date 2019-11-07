module CFExec
  class UserFeaturesController < ExecController
    def create
      @user = User.find(params[:user_id])

      feature_flag = FeatureFlag.new
      feature_flag.assign_attributes(params.require(:feature).permit(:identifier))
      feature_flag.resource = @user
      feature_flag.save!

      redirect_to exec_user_path(@user)
    end

    def destroy
      @user = User.find(params[:user_id])

      FeatureFlag.revoke(resource: @user, identifier: params[:id])

      redirect_to exec_user_path(@user)
    end
  end
end
