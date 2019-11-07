class NewCompanyUserForm
  include ActiveModel::Model

  attr_internal_accessor :current_company

  attr_accessor :email
  attr_accessor :is_admin
  attr_accessor :send_invitation_email
  attr_accessor :enable_user_notifications

  attr_reader :user
  attr_reader :user_is_new
  alias_method :user_is_new?, :user_is_new

  validates! :current_company, presence: true
  validates :email, presence: true, format: { with: Devise.email_regexp }

  def initialize(params = {})
    # Defaults
    self.enable_user_notifications = false
    self.send_invitation_email = true

    self.current_company = params.delete(:current_company)

    assign_attributes(params)
  end

  def assign_attributes(params = {})
    params.each do |attr, value|
      self.public_send("#{attr}=", value)
    end if params
  end

  def send_invitation_email?
    [true, "1"].include?(@send_invitation_email)
  end

  def enable_user_notifications?
    [true, "1"].include?(@enable_user_notifications)
  end

  def email=(value)
    @email = value ? value.downcase : value
  end

  def save
    return false if invalid?

    ActiveRecord::Base.transaction do
      existing_user = User.find_by_email(email)

      if existing_user && !existing_user.is_customer?
        if existing_user.company == current_company
          @user = existing_user
          return true # We don't need to do anything as the user is already a company user in the current company
        else
          errors.add(:email, "is already in use by someone else")
          return false
        end
      end

      @user = existing_user || User.new(email: email)
      @user_is_new = user.new_record?

      user.assign_attributes(company: current_company, is_customer: false, is_admin: is_admin)
      user.skip_confirmation_notification! # We don't want to send the default confirmation email
      user.save(validate: false) # Skip validations because the missing password is invalid

      if user_is_new?
        if enable_user_notifications?
          EmailSettings.build_with_all_set(user: user).save!
        else
          EmailSettings.build_with_all_unset(user: user).save!
        end
      end
    end

    if send_invitation_email?
      if user_is_new?
        user.deliver_new_company_user_welcome_notification_later(company: current_company)
      else
        user.deliver_existing_company_user_welcome_notification_later(company: current_company)
      end
    end

    true
  end
end
