class CustomerBulkCreate
  CUSTOMER_COLUMN_NAMES = [
    :company_id,
    :customer_id,
    :name,
    :external_accounting_number,
    :created_at,
    :updated_at,
  ]

  ADDRESS_BOOK_COLUMN_NAMES = [
    :customer_id,
    :created_at,
    :updated_at,
  ]

  ADDRESS_COLUMN_NAMES = [
    :reference_id,
    :reference_type,
    :company_name,
    :attention,
    :address_line1,
    :address_line2,
    :address_line3,
    :zip_code,
    :city,
    :country_code,
    :country_name,
    :state_code,
    :phone_number,
    :email,
    :created_at,
    :updated_at,
  ]

  RECORDING_COLUMN_NAMES = [
    :created_at,
    :updated_at,
    :company_id,
    :company_scoped_id,
    :type,
    :customer_name,
    :normalized_customer_name,
    :recordable_id,
    :recordable_type,
  ]

  USER_COLUMN_NAMES = [
    :company_id,
    :customer_id,
    :is_customer,
    :email,
    :created_at,
    :updated_at,
  ]

  EMAIL_SETTINGS_COLUMN_NAMES = [
    :user_id,
    :create,
    :book,
    :autobook_with_warnings,
    :ship,
    :delivered,
    :problem,
    :cancel,
    :comment,
    :pickup_create,
    :pickup_book,
    :pickup_pickup,
    :pickup_problem,
    :pickup_cancel,
    :pickup_comment,
    :rfq_create,
    :rfq_propose,
    :rfq_accept,
    :rfq_decline,
    :rfq_book,
    :rfq_cancel,
    :created_at,
    :updated_at,
  ]

  USER_CUSTOMER_ACCESS_COLUMN_NAMES = [
    :created_at,
    :user_id,
    :company_id,
    :customer_id,
  ]

  attr_reader :company
  attr_reader :customer_rows
  attr_accessor :send_invitation_email
  alias_method :send_invitation_email?, :send_invitation_email

  def initialize(company:, customer_rows:)
    @company = company
    @customer_rows = customer_rows
  end

  def perform!
    company.with_lock do
      @inserted_customer_ids = create_customers!
      create_address_books!
      create_addresses!
      create_customer_recordings!

      @inserted_user_ids = create_new_users!
      create_user_email_settings_for_new_users!

      create_user_customer_accesses!
    end

    deliver_invitation_emails_later! if send_invitation_email?
  end

  private

  attr_reader :inserted_customer_ids
  attr_reader :company_scoped_customer_ids
  attr_reader :inserted_user_ids

  def create_customers!(created_at: Time.now)
    @company_scoped_customer_ids = []

    rows_attributes = customer_rows.map do |customer_row|
      company_scoped_customer_id = company.update_next_customer_id_without_locking
      @company_scoped_customer_ids << company_scoped_customer_id

      {
        company_id: company.id,
        customer_id: company_scoped_customer_id,
        name: customer_row.company_name,
        external_accounting_number: customer_row.account_number,
        created_at: created_at,
        updated_at: created_at,
      }
    end

    bulk_insertion = BulkInsertion.new(rows_attributes, column_names: CUSTOMER_COLUMN_NAMES, model_class: ::Customer)
    bulk_insertion.perform!
    bulk_insertion.inserted_ids
  end

  def create_address_books!(created_at: Time.now)
    rows_attributes = inserted_customer_ids.map do |customer_id|
      {
        customer_id: customer_id,
        created_at: created_at,
        updated_at: created_at,
      }
    end

    bulk_insertion = BulkInsertion.new(rows_attributes, column_names: ADDRESS_BOOK_COLUMN_NAMES, model_class: ::AddressBook)
    bulk_insertion.perform!
  end

  def create_addresses!(created_at: Time.now)
    rows_attributes = customer_rows.zip(inserted_customer_ids).map do |customer_row, customer_id|
      {
        reference_id: customer_id,
        reference_type: "Customer",
        company_name: customer_row.company_name,
        attention: customer_row.attention,
        address_line1: customer_row.address_1,
        address_line2: customer_row.address_2,
        address_line3: customer_row.address_3,
        zip_code: customer_row.zip_code,
        city: customer_row.city,
        country_code: customer_row.downcased_country_code,
        country_name: customer_row.country_name,
        state_code: customer_row.state_code,
        phone_number: customer_row.phone,
        email: customer_row.email,
        created_at: created_at,
        updated_at: created_at,
      }
    end

    bulk_insertion = BulkInsertion.new(rows_attributes, column_names: ADDRESS_COLUMN_NAMES, model_class: ::Contact)
    bulk_insertion.perform!
  end

  def create_customer_recordings!(created_at: Time.now)
    rows_attributes = customer_rows.zip(inserted_customer_ids, company_scoped_customer_ids).map do |customer_row, customer_id, company_scoped_customer_id|
      {
        created_at: created_at,
        updated_at: created_at,
        company_id: company.id,
        company_scoped_id: company_scoped_customer_id,
        type: "CustomerRecordings::Customer",
        customer_name: customer_row.company_name,
        normalized_customer_name: CustomerRecording.normalize_customer_name(customer_row.company_name),
        recordable_id: customer_id,
        recordable_type: "Customer",
      }
    end

    bulk_insertion = BulkInsertion.new(rows_attributes, column_names: RECORDING_COLUMN_NAMES, model_class: ::CustomerRecording)
    bulk_insertion.perform!
  end

  def create_new_users!(created_at: Time.now)
    rows_attributes = new_emails.map do |email|
      {
        company_id: nil,
        customer_id: nil,
        is_customer: true,
        email: email,
        created_at: created_at,
        updated_at: created_at,
      }
    end

    bulk_insertion = BulkInsertion.new(rows_attributes, column_names: USER_COLUMN_NAMES, model_class: ::User)
    bulk_insertion.perform!
    bulk_insertion.inserted_ids
  end

  def create_user_email_settings_for_new_users!(created_at: Time.now)
    rows_attributes = inserted_user_ids.map do |user_id|
      {
        user_id: user_id,
        create: true,
        book: true,
        autobook_with_warnings: true,
        ship: true,
        delivered: true,
        problem: true,
        cancel: true,
        comment: true,
        pickup_create: true,
        pickup_book: true,
        pickup_pickup: true,
        pickup_problem: true,
        pickup_cancel: true,
        pickup_comment: true,
        rfq_create: true,
        rfq_propose: true,
        rfq_accept: true,
        rfq_decline: true,
        rfq_book: true,
        rfq_cancel: true,
        created_at: created_at,
        updated_at: created_at,
      }
    end

    bulk_insertion = BulkInsertion.new(rows_attributes, column_names: EMAIL_SETTINGS_COLUMN_NAMES, model_class: ::EmailSettings)
    bulk_insertion.perform!
    bulk_insertion.inserted_ids
  end

  def create_user_customer_accesses!(created_at: Time.now)
    rows_attributes = user_ids_per_customer_row.zip(inserted_customer_ids).map do |user_id, customer_id|
      {
        created_at: created_at,
        user_id: user_id,
        company_id: company.id,
        customer_id: customer_id,
      }
    end

    bulk_insertion = BulkInsertion.new(rows_attributes, column_names: USER_CUSTOMER_ACCESS_COLUMN_NAMES, model_class: ::UserCustomerAccess)
    bulk_insertion.perform!
  end

  def deliver_invitation_emails_later!
    # TODO: Let's at some point change this part to enqueue a bunch of background jobs that take user id and customer id as arguments.

    customer_rows.zip(inserted_customer_ids).each do |customer_row, customer_id|
      if new_emails.include?(customer_row.normalized_email)
        user = User.find_by_email!(customer_row.normalized_email)
        customer = Customer.find(customer_id)
        user.deliver_new_customer_user_welcome_notification_later(customer: customer)
      elsif existing_emails.include?(customer_row.normalized_email)
        user = User.find_by_email!(customer_row.normalized_email)
        customer = Customer.find(customer_id)
        user.deliver_existing_customer_user_welcome_notification_later(customer: customer)
      else
        raise "The email should either be new or an existing one"
      end
    end
  end

  def user_ids_per_customer_row
    # At this point all the necessary users should be created
    latest_email_user_id_mapping = email_user_id_mapping

    customer_rows.map do |customer_row|
      latest_email_user_id_mapping.fetch(customer_row.normalized_email)
    end
  end

  def new_emails
    @new_emails ||= Set.new(customer_rows.map(&:normalized_email)) - existing_emails
  end

  def existing_emails
    @existing_emails ||= Set.new(look_up_user_emails)
  end

  def email_user_id_mapping
    Hash[look_up_users.select(:id, :email).map { |user| [normalize_email(user.email), user.id] }]
  end

  def look_up_users
    User.where("LOWER(email) IN (?)", customer_rows.map(&:normalized_email))
  end

  def look_up_user_emails
    look_up_users.pluck(:email).map { |email| normalize_email(email) }
  end

  def normalize_email(email)
    email.downcase.strip
  end
end
