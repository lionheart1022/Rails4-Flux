class User < ActiveRecord::Base
  devise(
    :database_authenticatable,
    :recoverable,
    :rememberable,
    :trackable,
    :validatable,
    :confirmable,
    :lockable,
    # :timeoutable,
  )

  belongs_to :company
  belongs_to :customer
  has_one :email_settings, dependent: :destroy
  has_many :user_customer_accesses
  has_many :access_to_customers, through: :user_customer_accesses, class_name: "Customer", source: :customer
  has_one :truck_driver

  validates :email, presence: true, uniqueness: { case_sensitive: false }

  # PUBLIC API

  class << self
    def create_company_user(company_id: nil, user_data: nil)
      # We keep this method around for now because it is being invoked in db/seeds.rb
      # - the seeds file itself is not working (also before this deprecation) so let's get that fixed first.
      raise "Do not use this method"
    end

    def find_by_raw_confirmation_token(raw_confirmation_token)
      confirmation_token = Devise.token_generator.digest(self, :confirmation_token, raw_confirmation_token)
      find_by_confirmation_token(confirmation_token)
    end
  end

  def find_customer_with_access_to_by_params_identifier(params_identifier)
    user_customer_accesses.active.find_by_params_identifier(params_identifier)
  end

  def deliver_new_customer_user_welcome_notification_later(customer:)
    # Do like `#send_confirmation_instructions` (Devise)
    unless @raw_confirmation_token
      generate_confirmation_token!
    end

    mail = CustomerUserNotifier.welcome_new_user(
      user: self,
      customer: customer,
      raw_confirmation_token: @raw_confirmation_token,
    )

    mail.deliver_later(queue: "imports")
  end

  def deliver_existing_customer_user_welcome_notification_later(customer:)
    unless confirmed?
      return deliver_new_customer_user_welcome_notification_later(customer: customer)
    end

    mail = CustomerUserNotifier.welcome_already_confirmed_user(
      user: self,
      customer: customer,
    )

    mail.deliver_later(queue: "imports")
  end

  def deliver_new_company_user_welcome_notification_later(company:)
    # Do like `#send_confirmation_instructions` (Devise)
    unless @raw_confirmation_token
      generate_confirmation_token!
    end

    mail = CompanyUserNotifier.welcome_new_user(
      user: self,
      company: company,
      raw_confirmation_token: @raw_confirmation_token,
    )

    mail.deliver_later(queue: "imports")
  end

  def deliver_existing_company_user_welcome_notification_later(company:)
    unless confirmed?
      return deliver_new_company_user_welcome_notification_later(company: company)
    end

    mail = CompanyUserNotifier.welcome_already_confirmed_user(
      user: self,
      company: company,
    )

    mail.deliver_later(queue: "imports")
  end

  def deliver_new_truck_driver_user_welcome_notification_later(company:)
    # Do like `#send_confirmation_instructions` (Devise)
    unless @raw_confirmation_token
      generate_confirmation_token!
    end

    mail = TruckDriverNotifier.welcome_new_user(
      user: self,
      company: company,
      raw_confirmation_token: @raw_confirmation_token,
    )

    mail.deliver_later(queue: "imports")
  end
end
