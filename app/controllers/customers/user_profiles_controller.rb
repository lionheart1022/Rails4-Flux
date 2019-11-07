class Customers::UserProfilesController < CustomersController
  def show
    @change_password_form = ChangePasswordForm.new(user: current_user)
  end

  def update
    @change_password_form = ChangePasswordForm.new(change_password_params)
    @change_password_form.user = current_user

    if @change_password_form.save
      sign_in @change_password_form.resource, bypass: true
      redirect_to customers_user_profile_path, notice: "Your password has been changed"
    else
      render :show
    end
  end

  private

  def change_password_params
    params.fetch(:user, {}).permit(
      :current_password,
      :new_password,
      :new_password_confirmation,
    )
  end

  class ChangePasswordForm
    include ActiveModel::Model

    attr_accessor :user
    attr_accessor :current_password
    attr_accessor :new_password
    attr_accessor :new_password_confirmation

    attr_reader :resource

    validates! :user, presence: true
    validates :new_password, presence: true, confirmation: true, length: { within: Devise.password_length }

    validate :current_password_must_be_valid

    def save
      return false if invalid?

      @resource = User.find(user.id)
      update_successful = resource.update_with_password(
        current_password: current_password,
        password: new_password,
        password_confirmation: new_password_confirmation,
      )

      if update_successful
        true
      else
        raise "Could not update user"
      end
    end

    private

    def current_password_must_be_valid
      return if !user

      if current_password.blank? || !user.valid_password?(current_password)
        errors.add(:current_password, "is incorrect")
      end
    end
  end
end
