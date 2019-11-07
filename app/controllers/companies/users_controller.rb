class Companies::UsersController < CompaniesController
  def index
    @users = current_company.all_company_users.order(email: :asc)
  end

  def new
    @form = NewCompanyUserForm.new(current_company: current_company)
  end

  def create
    @form = NewCompanyUserForm.new(current_company: current_company)
    @form.assign_attributes(params.require(:user).permit(:email, :is_admin, :send_invitation_email, :enable_user_notifications))

    if @form.save
      redirect_to url_for(action: "index")
    else
      render :new
    end
  end

  def show
    @user = current_company.find_company_user(params[:id], not_user_id: current_user.id)

    render :edit
  end

  def edit
    @user = current_company.find_company_user(params[:id], not_user_id: current_user.id)
  end

  def update
    user = current_company.find_company_user(params[:id], not_user_id: current_user.id)
    user.assign_attributes(params.fetch(:user, {}).permit(:is_admin))
    user.save(validate: false) # Skip validations because the password could be missing

    redirect_to url_for(action: "index")
  end

  def destroy
    ActiveRecord::Base.transaction do
      user = current_company.find_company_user(params[:id], not_user_id: current_user.id)

      # Disable access to company, not actually delete
      user.company = nil
      user.is_customer = true
      user.is_admin = false

      user.save(validate: false) # Skip validations because the password could be missing
    end

    redirect_to url_for(action: "index")
  end

  private

  def set_current_nav
    @current_nav = "users"
  end
end
