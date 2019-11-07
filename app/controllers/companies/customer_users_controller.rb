class Companies::CustomerUsersController < CompaniesController
  def index
    @customer = Customer.where(company_id: current_company.id).find(params[:customer_id])
    @users = @customer.users_with_access.order(email: :asc).page(params[:page])
  end

  def new
    @customer = current_company.find_customer(params[:customer_id])
    @user = @customer.new_user(send_invitation_email: true)
  end

  def create
    @customer = current_company.find_customer(params[:customer_id])
    @user = @customer.new_user(user_params)

    if @customer.save_new_user(form_model: @user)
      redirect_to companies_customer_users_path(@customer)
    else
      render :new
    end
  end

  def destroy
    @customer = current_company.find_customer(params[:customer_id])
    @customer.revoke_user_access!(user_id: params[:id])

    redirect_to companies_customer_users_path(@customer)
  end

  private

  def set_current_nav
    @current_nav = "customers"
  end

  def user_params
    params.require(:user).permit(
      :email,
      :send_invitation_email,
      :enable_user_notifications,
    )
  end
end
