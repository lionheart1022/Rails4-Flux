class CustomerUserConfirmationsController < ApplicationController
  include SetCompanyFromHost

  helper_method :layout_config
  before_action :require_valid_confirmation_token

  def show
    @form = ChoosePasswordForm.new(user_record: @user)
  end

  def update
    @form = ChoosePasswordForm.new(params.require(:user).permit(:password, :password_confirmation))
    @form.user_record = @user

    if @form.save
      redirect_to user_confirmation_path(confirmation_token: params[:confirmation_token])
    else
      render :show
    end
  end

  private

  def require_valid_confirmation_token
    if Rails.env.development? && params[:confirmation_token].blank? && params[:dummy] == "1"
      # This is just provided as a way of testing the show view (without it actually working)
      @user = User.first # Just select a user, not important who
      return
    end

    if params[:confirmation_token].blank?
      return render(nothing: true, status: :bad_request)
    end

    @user = User.find_by_raw_confirmation_token(params[:confirmation_token])

    if @user.nil?
      return render(nothing: true, status: :bad_request)
    end
  end

  def layout_config
    @_layout_config ||= begin
      config = @company ? LayoutConfig.new_from_company(@company) : LayoutConfig.new_generic

      config.body_class = "without_sidebar"
      config.root_path = new_user_session_path

      config
    end
  end

  class ChoosePasswordForm
    include ActiveModel::Model

    attr_accessor :user_record
    attr_accessor :password, :password_confirmation

    validates! :user_record, presence: true
    # The same validations as the ones inside the Validatable Devise module
    validates :password, presence: true, confirmation: true, length: { within: Devise.password_length }

    def save
      return false if invalid?

      user_record.assign_attributes(password: password, password_confirmation: password_confirmation)
      user_record.save!

      true
    end
  end
end
