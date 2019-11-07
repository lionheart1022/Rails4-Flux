class Customer < ActiveRecord::Base
  has_many :user_customer_accesses
  has_many :active_user_customer_accesses, -> { active }, class_name: "UserCustomerAccess"
  has_many :users_with_access, through: :active_user_customer_accesses, class_name: "User", source: :user
  has_one :address, class_name: 'Contact', as: :reference
  has_one :address_book, dependent: :destroy
  has_many :contacts, through: :address_book
  has_many :users, dependent: :destroy
  has_many :shipments, dependent: :destroy
  has_many :pickups, dependent: :destroy
  has_many :end_of_day_manifests
  belongs_to :company
  has_many :customer_carrier_products, -> { where is_disabled: false }
  has_many :carrier_products, through: :customer_carrier_products
  has_many :sales_prices, through: :customer_carrier_products
  has_many :tokens, as: :owner

  accepts_nested_attributes_for :address, :customer_carrier_products, :carrier_products

  after_commit :update_related_customer_recordings, on: [:update]

  scope :sorted_by_name_desc, -> { order("name DESC") }
  scope :sorted_by_name_asc, -> { order("name ASC") }

  class << self

    # PUBLIC API

    def create_customer(company_id: nil, customer_data: nil, contact_data: nil, id_generator: nil)
      customer = nil

      Customer.transaction do
        customer = self.new({
          company_id:                 company_id,
          customer_id:                id_generator.update_next_customer_id,
          name:                       customer_data[:name],
          external_accounting_number: customer_data[:external_accounting_number]
        })

        user = User.new({
          company_id:            company_id,
          customer:              customer,
          is_customer:           true,
          email:                 customer_data[:email],
          password:              customer_data[:password],
          password_confirmation: customer_data[:password]
        })

        customer.address = Contact.create_contact(reference: customer, contact_data: contact_data)
        customer.save!
        user.save!

        EmailSettings.create!(user_id: user.id)

        AddressBook.create!({
          customer_id: customer.id
        })
      end

      return customer
    rescue => e
      raise ModelError.new(e.message, customer)
    end

    # Finders

    def find_company_customers(company_id: nil)
      self.where(company_id: company_id)
    end

    def autocomplete_search(company_id: nil, customer_name: nil)
      self.find_company_customers(company_id: company_id).where("name ILIKE ?", "%#{customer_name}%")
    end

    def find_company_customer(company_id: nil, customer_id: nil)
      self.find_company_customers(company_id: company_id).where(id: customer_id).first
    end

    def find_user(company_id: nil, customer_id: nil)
      self.find_company_customer(company_id: company_id, customer_id: customer_id).users.first
    end

    def find_address(company_id: nil, customer_id: nil)
      self.find_company_customer(company_id: company_id, customer_id: customer_id).address
    end

    def find_customer(customer_id: nil)
      self.where(id: customer_id).first
    end
  end

  # INSTANCE API

  def ferry_booking_enabled?
    CustomerCarrierProduct
      .find_enabled_customer_carrier_products(customer_id: id)
      .where(type: "ScandlinesCarrierProduct")
      .exists?
  end

  def enable_dangerous_goods!
    update!(allow_dangerous_goods: true)
  end

  def disable_dangerous_goods!
    update!(allow_dangerous_goods: false)
  end

  def unique_shipment_id(shipment_id)
    "#{self.customer_id}-#{shipment_id}"
  end

  def unique_pickup_id(pickup_id)
    "#{self.customer_id}-#{pickup_id}"
  end

  def update_next_shipment_id
    self.with_lock do
      self.increment!(:current_shipment_id)
    end
    return self.current_shipment_id
  end

  def update_next_pickup_id
    self.with_lock do
      self.increment!(:current_pickup_id)
    end
    return self.current_pickup_id
  end

  def update_next_end_of_day_manifest_id
    self.with_lock do
      self.increment!(:current_end_of_day_manifest_id)
    end
    return self.current_end_of_day_manifest_id
  end

  def create_end_of_day_manifest!(*args, &block)
    end_of_day_manifest = nil

    transaction do
      next_end_of_day_manifest_id = update_next_end_of_day_manifest_id

      end_of_day_manifest = end_of_day_manifests.new(*args, &block)
      end_of_day_manifest.company_id = company_id
      end_of_day_manifest.end_of_day_manifest_id = next_end_of_day_manifest_id

      end_of_day_manifest.save!
    end

    end_of_day_manifest
  end

  def new_user(params = {})
    NewUserFormModel.new(params)
  end

  def save_new_user(form_model: nil, params: nil)
    new_user_form_model = form_model || NewUserFormModel.new(params)

    return false if new_user_form_model.invalid?

    transaction do
      user_email = new_user_form_model.email.downcase
      user = User.find_by_email(user_email) || User.new(company: nil, customer: nil, is_customer: true, email: user_email)

      if user.new_record?
        user.skip_confirmation_notification! # We don't want to send the default confirmation email
        user.save(validate: false) # Skip validations because the missing password is invalid
        grant_access_to_user!(user)
        user.deliver_new_customer_user_welcome_notification_later(customer: self) if new_user_form_model.send_invitation_email?

        if new_user_form_model.enable_user_notifications?
          EmailSettings.build_with_all_set(user: user).save!
        else
          EmailSettings.build_with_all_unset(user: user).save!
        end
      else
        grant_access_to_user!(user)
        user.deliver_existing_customer_user_welcome_notification_later(customer: self) if new_user_form_model.send_invitation_email?
      end
    end

    true
  end

  def grant_access_to_user!(user)
    UserCustomerAccess.find_or_create_by!(company: company, customer: self, user: user, revoked_at: nil)
  end

  def revoke_user_access!(user_id:)
    UserCustomerAccess.revoke_all(company: company, customer: self, user_id: user_id)
  end

  def carrier_products_with_active_rate_sheets
    customer_recording = company.find_customer_recording(self)
    rate_sheets_for_customer = RateSheet.where(company: company, customer_recording: customer_recording)

    candidate_carrier_products =
      CarrierProduct.all.includes(:customer_carrier_products)
      .where(customer_carrier_products: { customer_id: id, is_disabled: false })
      .where(is_disabled: false)
      .where(id: rate_sheets_for_customer.select(:carrier_product_id))

    candidate_carrier_products.select do |carrier_product|
      latest_rate_sheet = rate_sheets_for_customer.order(id: :desc).find_by(carrier_product: carrier_product)
      customer_carrier_product = CustomerCarrierProduct.find_by(customer: self, carrier_product: carrier_product)
      base_price_document_upload = PriceDocumentUpload.active.find_by(company: company, carrier_product: carrier_product)

      if latest_rate_sheet.nil? || customer_carrier_product.nil? || base_price_document_upload.nil?
        false
      else
        current_rate_sheet = rate_sheets_for_customer.new(base_price_document_upload: base_price_document_upload)
        current_rate_sheet.build_1_level_margin(customer_carrier_product: customer_carrier_product)

        # Select if there is no change
        current_rate_sheet.no_change?(latest_rate_sheet)
      end
    end
  end

  def latest_active_rate_sheet_for(carrier_product_id:)
    customer_recording = company.find_customer_recording(self)
    rate_sheets_for_customer = RateSheet.where(company: company, customer_recording: customer_recording)

    latest_rate_sheet = rate_sheets_for_customer.order(id: :desc).find_by(carrier_product_id: carrier_product_id)
    customer_carrier_product = CustomerCarrierProduct.find_by(customer: self, carrier_product_id: carrier_product_id)
    base_price_document_upload = PriceDocumentUpload.active.find_by(company: company, carrier_product_id: carrier_product_id)

    if latest_rate_sheet.nil? || customer_carrier_product.nil? || base_price_document_upload.nil?
      nil
    else
      current_rate_sheet = rate_sheets_for_customer.new(base_price_document_upload: base_price_document_upload)
      current_rate_sheet.build_1_level_margin(customer_carrier_product: customer_carrier_product)

      current_rate_sheet.no_change?(latest_rate_sheet) ? latest_rate_sheet : nil
    end
  end

  def find_rate_sheet_by_id(rate_sheet_id)
    RateSheet
      .where(company: company)
      .where(customer_recording: company.find_customer_recording(self))
      .find(rate_sheet_id)
  end

  def create_pickup(*args, &block)
    pickup = Pickup.new(*args, &block)
    pickup.company_id = company_id
    pickup.customer_id = id
    pickup.state ||= Pickup::States::CREATED

    if pickup.valid?
      transaction do
        pickup.pickup_id = self.update_next_pickup_id
        pickup.unique_pickup_id = "#{self.id}-#{self.customer_id}-#{pickup.pickup_id}"
        pickup.save!

        pickup.events.create!(company_id: company_id, customer_id: id, event_type: Pickup::Events::CREATE)
      end

      PickupNotificationManager.handle_event(pickup, event: Pickup::Events::CREATE)
    end

    pickup
  end

  def autocomplete_contacts(term)
    if address_book
      address_book.contacts.autocomplete_search(company_name: term)
    else
      Contact.none
    end
  end

  private

  def update_related_customer_recordings
    CustomerRecording.where(recordable: self).each(&:save)
  end

  class NewUserFormModel
    include ActiveModel::Model

    attr_accessor :email
    attr_accessor :send_invitation_email
    attr_accessor :enable_user_notifications

    validates :email, presence: true, format: { with: Devise.email_regexp }

    def send_invitation_email?
      [true, "1"].include?(@send_invitation_email)
    end

    def enable_user_notifications?
      [true, "1"].include?(@enable_user_notifications)
    end
  end
end
