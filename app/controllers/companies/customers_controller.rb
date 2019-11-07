class Companies::CustomersController < CompaniesController
  def new
    form = NewForm.new(company: current_company)
    @view_model = view_model_when_creating(form: form)
  end

  def create
    form = NewForm.new(params_when_creating.merge(company: current_company))
    @view_model = view_model_when_creating(form: form)

    if form.save
      redirect_to companies_customer_path(form.customer_record)
    else
      render :new
    end
  end

  def settings
    @customer = current_company.customers.find(params[:id])
  end

  private

  def set_current_nav
    @current_nav = "customers"
  end

  def params_when_editing
    params.require(:customer).permit(
      :name,
      :email,
      :external_accounting_number,
      :attention,
      :address_line1,
      :address_line2,
      :address_line3,
      :zip_code,
      :city,
      :country_code,
      :state_code,
      :phone_number,
      :cvr_number,
      :note,
    )
  end

  def params_when_creating
    params.require(:customer).permit(
      :name,
      :external_accounting_number,
      :email,
      :send_invitation_email,
      :enable_user_notifications,
      :attention,
      :address_line1,
      :address_line2,
      :address_line3,
      :zip_code,
      :city,
      :country_code,
      :state_code,
      :phone_number,
      :cvr_number,
      :note,
    )
  end

  def view_model_when_creating(form:)
    view_model = OpenStruct.new
    view_model.form = form
    view_model
  end

  class NewForm
    include ActiveModel::Model

    CUSTOMER_ATTRIBUTES = [
      :email,
      :attention,
      :address_line1,
      :address_line2,
      :address_line3,
      :zip_code,
      :city,
      :country_code,
      :state_code,
      :phone_number,
      :cvr_number,
      :note,
    ]

    attr_reader :customer_record

    attr_accessor :company
    attr_accessor :name
    attr_accessor :email
    attr_accessor :send_invitation_email
    attr_accessor :enable_user_notifications
    attr_accessor :attention
    attr_accessor :address_line1
    attr_accessor :address_line2
    attr_accessor :address_line3
    attr_accessor :zip_code
    attr_accessor :city
    attr_accessor :country_code
    attr_accessor :state_code
    attr_accessor :phone_number
    attr_accessor :cvr_number
    attr_accessor :note
    attr_accessor :external_accounting_number

    validates! :company, presence: true
    validates :email, presence: true, format: { with: Devise.email_regexp }
    validates :name, presence: true
    validates :address_line1, presence: true
    validates :country_code, presence: true

    def initialize(params = {})
      self.send_invitation_email = "1"
      self.enable_user_notifications = "1"

      super
    end

    def save
      if valid?
        Customer.transaction do
          @customer_record = company.create_customer!(
            name: name,
            external_accounting_number: external_accounting_number,
          )

          customer_record.build_address

          CUSTOMER_ATTRIBUTES.each do |attr|
            customer_record.address.public_send("#{attr}=", self.public_send(attr))
          end

          customer_record.address.company_name = name
          customer_record.address.save!

          user = User.find_by_email(email) || User.new(company: nil, customer: nil, is_customer: true, email: email)

          if user.new_record?
            user.skip_confirmation_notification! # We don't want to send the default confirmation email
            user.save(validate: false) # Skip validations because the missing password is invalid
            UserCustomerAccess.create!(company: company, customer: customer_record, user: user)
            user.deliver_new_customer_user_welcome_notification_later(customer: customer_record) if send_invitation_email?

            if enable_user_notifications?
              EmailSettings.build_with_all_set(user: user).save!
            else
              EmailSettings.build_with_all_unset(user: user).save!
            end
          else
            UserCustomerAccess.create!(company: company, customer: customer_record, user: user)
            user.deliver_existing_customer_user_welcome_notification_later(customer: customer_record) if send_invitation_email?
          end

          AddressBook.create!(customer_id: customer_record.id)
        end

        true
      else
        false
      end
    end

    def send_invitation_email?
      [true, "1"].include?(@send_invitation_email)
    end

    def enable_user_notifications?
      [true, "1"].include?(@enable_user_notifications)
    end
  end
end
