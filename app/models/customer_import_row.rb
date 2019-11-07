class CustomerImportRow
  include ActiveModel::Model

  class << self
    def build_from_spreadsheet(row:, header_row:)
      i = new

      header_row.values.each_with_index do |name, column_index|
        attr_name = name.to_s.downcase

        if PERMITTED_COLUMN_NAMES.include?(attr_name)
          i.public_send("#{attr_name}=", row.values[column_index])
        end
      end

      i
    end
  end

  PERMITTED_COLUMN_NAMES = %w(
    company_name
    attention
    address_1
    address_2
    address_3
    zip_code
    city
    country_code
    state_code
    phone
    email
    account_number
  )

  PERMITTED_COLUMN_NAMES.each do |field|
    attr_accessor :"#{field}"
  end

  validates :email, presence: true, format: { with: Devise.email_regexp }
  validates :company_name, presence: true
  validates :address_1, presence: true
  validates :country_code, presence: true

  validate :country_code_must_be_valid

  def normalized_email
    if email
      email.downcase.strip
    end
  end

  def blank_row?
    PERMITTED_COLUMN_NAMES.all? { |field| self.public_send(field).blank? }
  end

  def attributes
    Hash[PERMITTED_COLUMN_NAMES.map { |field| [field, self.public_send(field)] }]
  end

  def json_attributes
    JSON.generate(attributes)
  end

  def country_name
    Country.find_country_by_alpha2(country_code).try(:name) if country_code.present?
  end

  def downcased_country_code
    country_code.downcase if country_code.present?
  end

  private

  def country_code_must_be_valid
    if country_code.present? && country_name.nil?
      errors.add(:country_code, "is not valid")
    end
  end
end
