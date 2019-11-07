class CompanyForm
  include ActiveModel::Model

  attr_accessor :name
  attr_accessor :initials
  attr_accessor :info_email
  attr_accessor :domain
  attr_accessor :user_email
  attr_accessor :send_invitation_email
  attr_accessor :enable_user_notifications

  attr_accessor :record, :user_record

  validate :company_record_must_be_valid
  validates :user_email, presence: true, if: Proc.new { |model| model.record.new_record? }
  validate :user_email_must_not_be_used_on_another_company

  class << self
    def edit_by_record_id(id)
      record = Company.find(id)

      new(
        record: record,
        name: record.name,
        initials: record.initials,
        info_email: record.info_email,
        domain: record.domain,
      )
    end
  end

  def initialize(params = {})
    self.send_invitation_email = true
    self.enable_user_notifications = true

    super
  end

  def assign_attributes(params = {})
    params.each do |attr, value|
      self.public_send("#{attr}=", value)
    end
  end

  def save
    self.record ||= Company.new(current_customer_id: 0, current_report_id: 0)

    record.name = name
    record.initials = initials.presence
    record.info_email = info_email
    record.domain = domain

    if user_email.present?
      self.user_record ||= User.find_by_email(user_email) || User.new(email: user_email)
    end

    Company.transaction do
      return false if invalid?

      record.save!

      EntityRelation.find_or_create_by!(from_reference: CargofluxCompany.find!, to_reference: record, relation_type: EntityRelation::RelationTypes::DIRECT_COMPANY)

      if user_email.present?
        user_record.company = record
        user_record.is_admin = true
        user_record.is_customer = false

        if user_record.new_record?
          user_record.skip_confirmation_notification! # We don't want to send the default confirmation email
          user_record.save(validate: false) # Skip validations because the password is missing

          user_record.deliver_new_company_user_welcome_notification_later(company: record) if send_invitation_email?

          if enable_user_notifications?
            EmailSettings.build_with_all_set(user: user_record).save!
          else
            EmailSettings.build_with_all_unset(user: user_record).save!
          end
        else
          user_record.skip_confirmation_notification! # We don't want to send the default confirmation email
          user_record.save(validate: false) # Skip validations because password could potentially be missing
          user_record.deliver_existing_company_user_welcome_notification_later(company: record) if send_invitation_email?
        end
      end
    end

    true
  end

  def record_id
    record ? record.id : nil
  end

  def send_invitation_email?
    ["1", true].include?(send_invitation_email)
  end

  def enable_user_notifications?
    ["1", true].include?(enable_user_notifications)
  end

  def user_fields?
    if record
      record.new_record?
    else
      true
    end
  end

  private

  def company_record_must_be_valid
    if record.nil?
      raise "`record` must be set before validations are run"
    end

    record.validate

    record.errors.each do |attribute, error|
      errors.add(attribute, error)
    end
  end

  def user_email_must_not_be_used_on_another_company
    return true if user_email.blank?

    if user_record.nil?
      raise "`user_record` must be set before validations are run"
    end

    return true if user_record.new_record?
    return true if user_record.is_customer? # Customer users are allowed to also become a company user (while still keeping customer access)

    if user_record.company_id != record.id
      errors.add(:user_email, "is already used on another company")
    end
  end
end
