class NewTruckDriverUserForm
  include ActiveModel::Model

  attr_internal_accessor :current_company
  attr_internal_accessor :truck_driver

  attr_accessor :email
  attr_accessor :send_invitation_email

  attr_reader :user

  validates! :current_company, presence: true
  validates! :truck_driver, presence: true
  validates :email, presence: true, format: { with: Devise.email_regexp }

  def initialize(params = {})
    # Defaults
    self.send_invitation_email = true

    self.current_company = params.delete(:current_company)
    self.truck_driver = params.delete(:truck_driver)

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

  def email=(value)
    @email = value ? value.downcase : value
  end

  def save
    return false if invalid?

    ActiveRecord::Base.transaction do
      existing_user = User.find_by_email(email)
      @user = existing_user || User.new(email: email)

      if existing_user && TruckDriver.where(user: existing_user).where.not(id: truck_driver.id).exists?
        errors.add(:email, "already in use by someone else")

        return false
      end

      user.skip_confirmation_notification! # We don't want to send the default confirmation email
      user.save(validate: false) # Skip validations because the missing password is invalid

      truck_driver.update!(user: user)
    end

    if send_invitation_email?
      unless user.confirmed?
        user.deliver_new_truck_driver_user_welcome_notification_later(company: current_company)
      end
    end

    true
  end
end
