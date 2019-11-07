class PasswordResetsController < ApplicationController
  include SetCompanyFromHost

  helper_method :layout_config

  def new
    @form = Form.new
  end

  def create
    @form = Form.new(params.fetch(:user, {}).permit(:email))

    if @form.reset_password
      redirect_to sent_password_reset_path(email: @form.email)
    else
      render :new
    end
  end

  def sent
  end

  def edit
    @form = ChoosePasswordForm.new(reset_password_token: params[:reset_password_token])
  end

  def update
    @form = ChoosePasswordForm.new(params_for_reset_password)

    if @form.save
      sign_in(@form.user)
      redirect_to admin_root_path
    else
      render :edit
    end
  end

  private

  def params_for_reset_password
    params.fetch(:user).permit(
      :reset_password_token,
      :password,
      :password_confirmation,
    )
  end

  def layout_config
    @_layout_config ||= begin
      config = @company ? LayoutConfig.new_from_company(@company) : LayoutConfig.new_generic

      config.body_class = "without_sidebar"
      config.root_path = new_user_session_path

      config
    end
  end

  class Form
    include ActiveModel::Model

    attr_accessor :email

    validates :email, presence: true, format: { with: Devise.email_regexp, message: "does not look like an email" }

    def reset_password
      return false if invalid?

      PasswordResetJob.perform_later(email.downcase)

      true
    end
  end

  class ChoosePasswordForm
    include ActiveModel::Model

    attr_reader :user

    attr_accessor :reset_password_token
    attr_accessor :password, :password_confirmation

    # The same validations as the ones inside the Validatable Devise module
    validates :reset_password_token, presence: true
    validates :password, presence: true, confirmation: true, length: { within: Devise.password_length }

    def save
      return false if invalid?

      reset_password_token_digest = Devise.token_generator.digest(::User, :reset_password_token, reset_password_token)

      User.transaction do
        @user = User.find_by_reset_password_token(reset_password_token_digest)

        unless user
          errors.add(:reset_password_token, :invalid)
          return false
        end

        unless user.reset_password_period_valid?
          errors.add(:reset_password_token, :expired)
          return false
        end

        user.confirm! unless user.confirmed?
        user.reset_password!(password, password_confirmation)
      end

      true
    end
  end
end
